import Foundation
import MapKit
import Observation
import SwiftUI

@Observable
final class LocationSearchViewModel {
    var searchQuery: String = ""
    var searchResults: [Place] = []
    var selectedPlace: Place?
    var route: Route?
    var isSearching: Bool = false
    var errorMessage: String?
    var mapCameraPosition: MapCameraPosition = .automatic

    let locationManager = LocationManager()

    private let searchService: LocationSearchServiceProtocol
    private let directionsService: DirectionsServiceProtocol

    init(
        searchService: LocationSearchServiceProtocol = LocationSearchService(),
        directionsService: DirectionsServiceProtocol = DirectionsService()
    ) {
        self.searchService = searchService
        self.directionsService = directionsService
    }

    var currentLocation: CLLocationCoordinate2D? {
        locationManager.currentLocation
    }

    @MainActor
    func search() async {
        guard !searchQuery.trimmingCharacters(in: .whitespaces).isEmpty else {
            searchResults = []
            return
        }

        isSearching = true
        errorMessage = nil

        do {
            let region: MKCoordinateRegion? = currentLocation.map {
                MKCoordinateRegion(
                    center: $0,
                    span: MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5)
                )
            }
            searchResults = try await searchService.search(query: searchQuery, region: region)
        } catch {
            errorMessage = "検索に失敗しました: \(error.localizedDescription)"
            searchResults = []
        }

        isSearching = false
    }

    @MainActor
    func selectPlace(_ place: Place) async {
        selectedPlace = place
        route = nil

        mapCameraPosition = .region(MKCoordinateRegion(
            center: place.coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        ))

        await calculateRoute(to: place)
    }

    @MainActor
    func calculateRoute(to destination: Place) async {
        guard let source = currentLocation else {
            errorMessage = "現在地を取得できません"
            return
        }

        do {
            route = try await directionsService.calculateRoute(
                from: source,
                to: destination.coordinate
            )

            if let route = route {
                let routeRect = route.polyline.boundingMapRect
                let region = MKCoordinateRegion(routeRect)
                let paddedRegion = MKCoordinateRegion(
                    center: region.center,
                    span: MKCoordinateSpan(
                        latitudeDelta: region.span.latitudeDelta * 1.3,
                        longitudeDelta: region.span.longitudeDelta * 1.3
                    )
                )
                mapCameraPosition = .region(paddedRegion)
            }
        } catch {
            errorMessage = "経路の計算に失敗しました: \(error.localizedDescription)"
        }
    }

    func requestLocationPermission() {
        locationManager.requestLocationPermission()
    }

    func clearSearch() {
        searchQuery = ""
        searchResults = []
        selectedPlace = nil
        route = nil
        errorMessage = nil
    }
}
