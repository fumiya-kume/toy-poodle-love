import Foundation
import MapKit
import os

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
        AppLogger.directions.info("ルート計算を開始します")

        let sourcePlacemark = MKPlacemark(coordinate: source)
        let destinationPlacemark = MKPlacemark(coordinate: destination)

        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: sourcePlacemark)
        request.destination = MKMapItem(placemark: destinationPlacemark)
        request.transportType = transportType.mkTransportType

        let directions = MKDirections(request: request)

        do {
            let response = try await directions.calculate()

            guard let mkRoute = response.routes.first else {
                AppLogger.directions.warning("経路が見つかりませんでした")
                return nil
            }

            let route = Route(mkRoute: mkRoute)
            let distanceKm = route.distance / 1000
            let timeMinutes = route.expectedTravelTime / 60
            AppLogger.directions.info("ルート計算完了: 距離 \(String(format: "%.1f", distanceKm))km、所要時間 \(Int(timeMinutes))分")
            return route
        } catch {
            AppLogger.directions.error("ルート計算に失敗しました: \(error.localizedDescription)")
            throw AppError.routeCalculationFailed(underlying: error)
        }
    }
}
