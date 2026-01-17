import Foundation
import MapKit

protocol LookAroundServiceProtocol {
    func fetchScene(for coordinate: CLLocationCoordinate2D) async throws -> MKLookAroundScene?
}

final class LookAroundService: LookAroundServiceProtocol {
    func fetchScene(for coordinate: CLLocationCoordinate2D) async throws -> MKLookAroundScene? {
        let request = MKLookAroundSceneRequest(coordinate: coordinate)
        return try await request.scene
    }
}
