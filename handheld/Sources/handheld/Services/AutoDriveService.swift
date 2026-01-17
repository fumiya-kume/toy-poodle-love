import Foundation
import MapKit
import os

/// オートドライブサービスのプロトコル。
///
/// ルートに沿ってLook Aroundシーンを取得・再生するための機能を提供します。
///
/// ## 概要
///
/// このプロトコルは以下の機能を定義します：
/// 1. ルートポリラインからドライブポイントの抽出
/// 2. 初期シーンの並列取得
/// 3. シーンの先読み取得
///
/// ## 使用例
///
/// ```swift
/// let service: AutoDriveServiceProtocol = AutoDriveService()
/// let points = service.extractDrivePoints(from: route.polyline, interval: 30)
///
/// let successCount = await service.fetchInitialScenes(
///     for: points,
///     initialCount: 3
/// ) { index, scene in
///     // シーン取得完了時の処理
/// }
/// ```
protocol AutoDriveServiceProtocol {
    /// ポリラインからドライブポイントを抽出する。
    ///
    /// 指定された間隔でルートに沿った座標点を抽出します。
    ///
    /// - Parameters:
    ///   - polyline: ルートのポリライン
    ///   - interval: ポイント間の距離（メートル）
    ///
    /// - Returns: 抽出されたドライブポイントの配列
    func extractDrivePoints(from polyline: MKPolyline, interval: CLLocationDistance) -> [RouteCoordinatePoint]

    /// 初期シーンを並列取得する。
    ///
    /// 再生開始前に必要な最初のN件のLook Aroundシーンを並列で取得します。
    ///
    /// - Parameters:
    ///   - points: ドライブポイントの配列
    ///   - initialCount: 初期取得する件数
    ///   - onSceneFetched: シーン取得完了時のコールバック
    ///
    /// - Returns: 成功した取得件数
    func fetchInitialScenes(
        for points: [RouteCoordinatePoint],
        initialCount: Int,
        onSceneFetched: @escaping @MainActor (Int, MKLookAroundScene?) -> Void
    ) async -> Int

    /// シーンを先読み取得する。
    ///
    /// 指定範囲のLook Aroundシーンを順次取得します。
    /// レート制限を考慮し、100msの間隔を空けて取得します。
    ///
    /// - Parameters:
    ///   - points: ドライブポイントの配列
    ///   - startIndex: 取得開始インデックス
    ///   - count: 取得件数
    ///   - onSceneFetched: シーン取得完了時のコールバック
    func prefetchScenes(
        for points: [RouteCoordinatePoint],
        from startIndex: Int,
        count: Int,
        onSceneFetched: @escaping @MainActor (Int, MKLookAroundScene?) -> Void
    ) async
}

/// オートドライブサービス。
///
/// ルートに沿ったLook Aroundシーンの取得と再生を管理します。
///
/// - SeeAlso: ``AutoDriveServiceProtocol``, ``AutoDriveConfiguration``
final class AutoDriveService: AutoDriveServiceProtocol {
    private let lookAroundService: LookAroundServiceProtocol
    private static let defaultInterval: CLLocationDistance = 30

    init(lookAroundService: LookAroundServiceProtocol = LookAroundService()) {
        self.lookAroundService = lookAroundService
    }

    func extractDrivePoints(
        from polyline: MKPolyline,
        interval: CLLocationDistance = AutoDriveService.defaultInterval
    ) -> [RouteCoordinatePoint] {
        let allCoordinates = polyline.coordinates
        guard !allCoordinates.isEmpty else {
            AppLogger.autoDrive.warning("ドライブポイントの抽出: 座標が空です")
            return []
        }

        var drivePoints: [RouteCoordinatePoint] = []
        var accumulatedDistance: CLLocationDistance = 0
        var lastPoint = allCoordinates[0]

        drivePoints.append(RouteCoordinatePoint(index: 0, coordinate: lastPoint))

        for coordinate in allCoordinates.dropFirst() {
            let distance = lastPoint.distance(to: coordinate)
            accumulatedDistance += distance

            if accumulatedDistance >= interval {
                drivePoints.append(RouteCoordinatePoint(
                    index: drivePoints.count,
                    coordinate: coordinate
                ))
                accumulatedDistance = 0
            }
            lastPoint = coordinate
        }

        if let lastCoord = allCoordinates.last,
           let lastDrivePoint = drivePoints.last,
           lastDrivePoint.coordinate.latitude != lastCoord.latitude ||
           lastDrivePoint.coordinate.longitude != lastCoord.longitude {
            drivePoints.append(RouteCoordinatePoint(
                index: drivePoints.count,
                coordinate: lastCoord
            ))
        }

        AppLogger.autoDrive.info("ドライブポイントを抽出しました: \(drivePoints.count)件")
        return drivePoints
    }

    func fetchInitialScenes(
        for points: [RouteCoordinatePoint],
        initialCount: Int,
        onSceneFetched: @escaping @MainActor (Int, MKLookAroundScene?) -> Void
    ) async -> Int {
        let targetCount = min(initialCount, points.count)
        let targetPoints = Array(points.prefix(targetCount))
        var successCount = 0
        let lookAroundService = lookAroundService

        AppLogger.autoDrive.info("初期シーン取得を開始します: \(targetCount)件")

        await withTaskGroup(of: (Int, MKLookAroundScene?).self) { group in
            for (idx, point) in targetPoints.enumerated() {
                group.addTask {
                    do {
                        let scene = try await lookAroundService.fetchScene(for: point.coordinate)
                        return (idx, scene)
                    } catch {
                        AppLogger.autoDrive.warning("初期シーン取得失敗: インデックス \(idx)")
                        return (idx, nil)
                    }
                }
            }

            for await (index, scene) in group {
                if scene != nil {
                    successCount += 1
                }
                await onSceneFetched(index, scene)
            }
        }

        AppLogger.autoDrive.info("初期シーン取得完了: \(targetCount)件中\(successCount)件成功")
        return successCount
    }

    func prefetchScenes(
        for points: [RouteCoordinatePoint],
        from startIndex: Int,
        count: Int,
        onSceneFetched: @escaping @MainActor (Int, MKLookAroundScene?) -> Void
    ) async {
        let endIndex = min(startIndex + count, points.count)
        guard startIndex < endIndex else { return }
        let lookAroundService = lookAroundService

        for index in startIndex..<endIndex {
            let point = points[index]

            // 既に取得済み（ローディング中でない）ならスキップ
            guard point.isLookAroundLoading else { continue }

            do {
                let scene = try await lookAroundService.fetchScene(for: point.coordinate)
                await onSceneFetched(index, scene)
            } catch {
                AppLogger.autoDrive.warning("プリフェッチ失敗: インデックス \(index)")
                await onSceneFetched(index, nil)
            }

            // レート制限のため少し待機
            try? await Task.sleep(for: .milliseconds(100))
        }
    }
}
