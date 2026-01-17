import Foundation
import MapKit
import os

/// Look Aroundシーン取得サービスのプロトコル。
///
/// MapKitのLook Aroundシーンを取得する機能を提供します。
///
/// ## 概要
///
/// このプロトコルは以下の機能を定義します：
/// - 単一座標でのシーン取得
/// - ナビゲーションステップに沿った段階的なシーン取得
///
/// ## 使用例
///
/// ```swift
/// let service: LookAroundServiceProtocol = LookAroundService()
/// if let scene = try await service.fetchScene(for: coordinate) {
///     // シーンを表示
/// }
/// ```
protocol LookAroundServiceProtocol {
    /// 指定座標のLook Aroundシーンを取得する。
    ///
    /// - Parameter coordinate: 取得する座標
    /// - Returns: Look Aroundシーン（利用不可の場合は`nil`）
    ///
    /// - Throws: 取得に失敗した場合
    func fetchScene(for coordinate: CLLocationCoordinate2D) async throws -> MKLookAroundScene?

    /// ナビゲーションステップに沿ってシーンを段階的に取得する。
    ///
    /// 最初の3件は並列取得、以降は順次取得します。
    ///
    /// - Parameters:
    ///   - steps: ナビゲーションステップの配列
    ///   - onSceneFetched: シーン取得完了時のコールバック
    func fetchScenesProgressively(
        for steps: [NavigationStep],
        onSceneFetched: @escaping @MainActor (Int, MKLookAroundScene?) -> Void
    ) async
}

/// Look Aroundシーン取得サービス。
///
/// ``LookAroundServiceProtocol``の実装クラスです。
/// キャッシュを活用して効率的にシーンを取得します。
///
/// - SeeAlso: ``LookAroundServiceProtocol``, ``LookAroundCacheService``
final class LookAroundService: LookAroundServiceProtocol {

    private let cacheService: LookAroundCacheService

    init(cacheService: LookAroundCacheService = LookAroundCacheService()) {
        self.cacheService = cacheService
    }

    func fetchScene(for coordinate: CLLocationCoordinate2D) async throws -> MKLookAroundScene? {
        AppLogger.lookAround.debug("Look Aroundシーン取得を開始します: (\(coordinate.latitude), \(coordinate.longitude))")

        // 1. メモリキャッシュをチェック
        if let cachedScene = await cacheService.cachedScene(for: coordinate) {
            AppLogger.lookAround.debug("メモリキャッシュからシーンを返却")
            return cachedScene
        }

        // 2. 利用不可と記録済みの座標はスキップ
        if await cacheService.isKnownUnavailable(for: coordinate) {
            AppLogger.lookAround.debug("利用不可キャッシュによりスキップ")
            return nil
        }

        // 3. APIから取得
        let request = MKLookAroundSceneRequest(coordinate: coordinate)
        let scene = try await request.scene

        // 4. キャッシュに保存
        await cacheService.cacheScene(scene, for: coordinate)

        return scene
    }

    func fetchScenesProgressively(
        for steps: [NavigationStep],
        onSceneFetched: @escaping @MainActor (Int, MKLookAroundScene?) -> Void
    ) async {
        let prioritySteps = Array(steps.prefix(3))
        var successCount = 0
        let totalCount = steps.count

        await withTaskGroup(of: (Int, MKLookAroundScene?).self) { group in
            for step in prioritySteps {
                group.addTask {
                    do {
                        let scene = try await self.fetchScene(for: step.coordinate)
                        return (step.stepIndex, scene)
                    } catch {
                        AppLogger.lookAround.warning("Look Aroundシーン取得失敗: (\(step.coordinate.latitude), \(step.coordinate.longitude))")
                        return (step.stepIndex, nil)
                    }
                }
            }
            for await (index, scene) in group {
                if scene != nil { successCount += 1 }
                await onSceneFetched(index, scene)
            }
        }

        for step in steps.dropFirst(3) {
            do {
                let scene = try await fetchScene(for: step.coordinate)
                if scene != nil { successCount += 1 }
                await onSceneFetched(step.stepIndex, scene)
            } catch {
                AppLogger.lookAround.warning("Look Aroundシーン取得失敗: (\(step.coordinate.latitude), \(step.coordinate.longitude))")
                await onSceneFetched(step.stepIndex, nil)
            }
            do {
                try await Task.sleep(for: .milliseconds(200))
            } catch {
                AppLogger.lookAround.warning("スリープが中断されました")
            }
        }

        AppLogger.lookAround.info("Look Aroundシーン取得完了: \(totalCount)件中\(successCount)件成功")
    }
}
