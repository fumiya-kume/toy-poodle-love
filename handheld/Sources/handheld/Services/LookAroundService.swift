import Foundation
import MapKit

protocol LookAroundServiceProtocol {
    func fetchScene(for coordinate: CLLocationCoordinate2D) async throws -> MKLookAroundScene?
    func fetchScenesProgressively(
        for steps: [NavigationStep],
        onSceneFetched: @escaping @MainActor (Int, MKLookAroundScene?) -> Void
    ) async
}

final class LookAroundService: LookAroundServiceProtocol {
    func fetchScene(for coordinate: CLLocationCoordinate2D) async throws -> MKLookAroundScene? {
        let request = MKLookAroundSceneRequest(coordinate: coordinate)
        return try await request.scene
    }

    func fetchScenesProgressively(
        for steps: [NavigationStep],
        onSceneFetched: @escaping @MainActor (Int, MKLookAroundScene?) -> Void
    ) async {
        let prioritySteps = Array(steps.prefix(3))

        await withTaskGroup(of: (Int, MKLookAroundScene?).self) { group in
            for step in prioritySteps {
                group.addTask {
                    let scene = try? await self.fetchScene(for: step.coordinate)
                    return (step.stepIndex, scene)
                }
            }
            for await (index, scene) in group {
                await onSceneFetched(index, scene)
            }
        }

        for step in steps.dropFirst(3) {
            let scene = try? await fetchScene(for: step.coordinate)
            await onSceneFetched(step.stepIndex, scene)
            try? await Task.sleep(for: .milliseconds(200))
        }
    }
}
