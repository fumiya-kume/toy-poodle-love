import Foundation
import MapKit
import os

protocol AutoDriveServiceProtocol {
    func extractDrivePoints(from polyline: MKPolyline, interval: CLLocationDistance) -> [RouteCoordinatePoint]

    /// 初期シーン取得（再生開始前に必要な最初のN件を並列取得）
    func fetchInitialScenes(
        for points: [RouteCoordinatePoint],
        initialCount: Int,
        onSceneFetched: @escaping @MainActor (Int, MKLookAroundScene?) -> Void
    ) async -> Int

    /// 先読み取得（指定範囲のシーンを順次取得）
    func prefetchScenes(
        for points: [RouteCoordinatePoint],
        from startIndex: Int,
        count: Int,
        onSceneFetched: @escaping @MainActor (Int, MKLookAroundScene?) -> Void
    ) async
}

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
