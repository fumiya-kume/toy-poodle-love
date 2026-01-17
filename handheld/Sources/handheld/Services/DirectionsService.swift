import Foundation
import MapKit

enum TransportType: String, CaseIterable, Identifiable {
    case walking
    case automobile

    var id: String { rawValue }

    var mkTransportType: MKDirectionsTransportType {
        switch self {
        case .walking: return .walking
        case .automobile: return .automobile
        }
    }

    var icon: String {
        switch self {
        case .walking: return "figure.walk"
        case .automobile: return "car.fill"
        }
    }

    var label: String {
        switch self {
        case .walking: return "徒歩"
        case .automobile: return "車"
        }
    }
}

protocol DirectionsServiceProtocol {
    func calculateRoute(from source: CLLocationCoordinate2D, to destination: CLLocationCoordinate2D) async throws -> Route?
    func calculateRoute(from source: CLLocationCoordinate2D, to destination: CLLocationCoordinate2D, transportType: TransportType) async throws -> Route?
}

final class DirectionsService: DirectionsServiceProtocol {
    func calculateRoute(from source: CLLocationCoordinate2D, to destination: CLLocationCoordinate2D) async throws -> Route? {
        try await calculateRoute(from: source, to: destination, transportType: .walking)
    }

    func calculateRoute(from source: CLLocationCoordinate2D, to destination: CLLocationCoordinate2D, transportType: TransportType) async throws -> Route? {
        let sourcePlacemark = MKPlacemark(coordinate: source)
        let destinationPlacemark = MKPlacemark(coordinate: destination)

        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: sourcePlacemark)
        request.destination = MKMapItem(placemark: destinationPlacemark)
        request.transportType = transportType.mkTransportType

        let directions = MKDirections(request: request)
        let response = try await directions.calculate()

        guard let mkRoute = response.routes.first else {
            return nil
        }

        return Route(mkRoute: mkRoute)
    }
}
