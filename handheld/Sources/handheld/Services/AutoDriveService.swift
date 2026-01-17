import Foundation
import MapKit
import os

protocol AutoDriveServiceProtocol {
    func extractDrivePoints(from polyline: MKPolyline, interval: CLLocationDistance) -> [RouteCoordinatePoint]
    func fetchAllScenes(
        for points: [RouteCoordinatePoint],
        onSceneFetched: @escaping @MainActor (Int, MKLookAroundScene?, Bool) -> Void
    ) async -> (successCount: Int, totalCount: Int)
}

final class AutoDriveService: AutoDriveServiceProtocol {
    private let lookAroundService: LookAroundServiceProtocol
    private let defaultInterval: CLLocationDistance = 30

    init(lookAroundService: LookAroundServiceProtocol = LookAroundService()) {
        self.lookAroundService = lookAroundService
    }

    func extractDrivePoints(
        from polyline: MKPolyline,
        interval: CLLocationDistance = 30
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

    func fetchAllScenes(
        for points: [RouteCoordinatePoint],
        onSceneFetched: @escaping @MainActor (Int, MKLookAroundScene?, Bool) -> Void
    ) async -> (successCount: Int, totalCount: Int) {
        var successCount = 0
        let totalCount = points.count

        AppLogger.autoDrive.info("Look Aroundシーンの一括取得を開始します: \(totalCount)件")

        let batchSize = 5

        for batchStart in stride(from: 0, to: points.count, by: batchSize) {
            let batchEnd = min(batchStart + batchSize, points.count)
            let batch = Array(batchStart..<batchEnd)

            await withTaskGroup(of: (Int, MKLookAroundScene?).self) { group in
                for index in batch {
                    let coordinate = points[index].coordinate
                    group.addTask {
                        do {
                            let scene = try await self.lookAroundService.fetchScene(for: coordinate)
                            return (index, scene)
                        } catch {
                            AppLogger.autoDrive.warning("Look Aroundシーン取得失敗: インデックス \(index)")
                            return (index, nil)
                        }
                    }
                }

                for await (index, scene) in group {
                    let isSuccess = scene != nil
                    if isSuccess {
                        successCount += 1
                    }
                    await onSceneFetched(index, scene, isSuccess)
                }
            }
        }

        AppLogger.autoDrive.info("Look Aroundシーン取得完了: \(totalCount)件中\(successCount)件成功")
        return (successCount, totalCount)
    }
}
