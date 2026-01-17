import Foundation
import MapKit

protocol DirectionsServiceProtocol {
    func calculateRoute(from source: CLLocationCoordinate2D, to destination: CLLocationCoordinate2D) async throws -> Route?
}

final class DirectionsService: DirectionsServiceProtocol {
    func calculateRoute(from source: CLLocationCoordinate2D, to destination: CLLocationCoordinate2D) async throws -> Route? {
        let sourcePlacemark = MKPlacemark(coordinate: source)
        let destinationPlacemark = MKPlacemark(coordinate: destination)

        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: sourcePlacemark)
        request.destination = MKMapItem(placemark: destinationPlacemark)
        request.transportType = .walking

        let directions = MKDirections(request: request)
        let response = try await directions.calculate()

        guard let mkRoute = response.routes.first else {
            return nil
        }

        return Route(mkRoute: mkRoute)
    }
}
