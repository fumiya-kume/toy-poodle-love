import Foundation
import MapKit
import Observation
import SwiftUI

enum LookAroundTarget: String, CaseIterable, Identifiable {
    case destination = "目的地"
    case nextStep = "次の曲がり角"

    var id: String { rawValue }
}

@Observable
final class LocationSearchViewModel {
    var searchQuery: String = ""
    var searchResults: [Place] = []
    var selectedPlace: Place?
    var route: Route?
    var isSearching: Bool = false
    var errorMessage: String?
    var mapCameraPosition: MapCameraPosition = .automatic

    var suggestions: [SearchSuggestion] = []
    var isSuggesting: Bool = false
    var showSuggestions: Bool = false

    // Look Around関連
    var destinationLookAroundScene: MKLookAroundScene?
    var nextStepLookAroundScene: MKLookAroundScene?
    var isLoadingLookAround: Bool = false
    var showLookAround: Bool = false
    var showLookAroundSheet: Bool = false
    var lookAroundTarget: LookAroundTarget = .destination

    let locationManager = LocationManager()

    private let searchService: LocationSearchServiceProtocol
    private let directionsService: DirectionsServiceProtocol
    private let completerService: LocationCompleterServiceProtocol
    private let lookAroundService: LookAroundServiceProtocol
    private var debounceTask: Task<Void, Never>?
    private let debounceInterval: Duration = .milliseconds(300)

    init(
        searchService: LocationSearchServiceProtocol = LocationSearchService(),
        directionsService: DirectionsServiceProtocol = DirectionsService(),
        completerService: LocationCompleterServiceProtocol? = nil,
        lookAroundService: LookAroundServiceProtocol = LookAroundService()
    ) {
        self.searchService = searchService
        self.directionsService = directionsService
        self.completerService = completerService ?? LocationCompleterService()
        self.lookAroundService = lookAroundService
        setupCompleterCallback()
    }

    private func setupCompleterCallback() {
        completerService.onSuggestionsUpdated = { [weak self] newSuggestions in
            Task { @MainActor in
                self?.suggestions = newSuggestions
                self?.isSuggesting = false
                self?.showSuggestions = !newSuggestions.isEmpty && !(self?.searchQuery.isEmpty ?? true)
            }
        }
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

                // Look Aroundを取得
                await fetchLookAroundScenes()
            }
        } catch {
            errorMessage = "経路の計算に失敗しました: \(error.localizedDescription)"
        }
    }

    // MARK: - Look Around

    var hasLookAroundAvailable: Bool {
        destinationLookAroundScene != nil || nextStepLookAroundScene != nil
    }

    var hasNextStep: Bool {
        guard let route = route else { return false }
        return !route.steps.isEmpty
    }

    var currentLookAroundScene: MKLookAroundScene? {
        switch lookAroundTarget {
        case .destination:
            return destinationLookAroundScene
        case .nextStep:
            return nextStepLookAroundScene
        }
    }

    var lookAroundLocationName: String {
        switch lookAroundTarget {
        case .destination:
            return selectedPlace?.name ?? "目的地"
        case .nextStep:
            return "次の曲がり角"
        }
    }

    @MainActor
    func fetchLookAroundScenes() async {
        isLoadingLookAround = true
        destinationLookAroundScene = nil
        nextStepLookAroundScene = nil

        // 目的地のLook Aroundを取得
        if let destination = selectedPlace?.coordinate {
            do {
                destinationLookAroundScene = try await lookAroundService.fetchScene(for: destination)
            } catch {
                print("Look Around fetch failed for destination: \(error.localizedDescription)")
            }
        }

        // 次の曲がり角のLook Aroundを取得
        if let firstStep = route?.steps.first {
            let stepCoordinate = firstStep.polyline.coordinate
            do {
                nextStepLookAroundScene = try await lookAroundService.fetchScene(for: stepCoordinate)
            } catch {
                print("Look Around fetch failed for next step: \(error.localizedDescription)")
            }
        }

        isLoadingLookAround = false

        // どちらかが利用可能なら表示
        if hasLookAroundAvailable {
            // 利用可能な方を選択
            if destinationLookAroundScene != nil {
                lookAroundTarget = .destination
            } else if nextStepLookAroundScene != nil {
                lookAroundTarget = .nextStep
            }
            showLookAround = true
        }
    }

    func dismissLookAround() {
        showLookAround = false
    }

    func openLookAroundSheet() {
        showLookAroundSheet = true
    }

    func showLookAroundCard() {
        if hasLookAroundAvailable {
            showLookAround = true
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
        suggestions = []
        showSuggestions = false
        debounceTask?.cancel()
        completerService.clear()
    }

    @MainActor
    func updateSuggestions() {
        debounceTask?.cancel()

        debounceTask = Task {
            do {
                try await Task.sleep(for: debounceInterval)

                guard !Task.isCancelled else { return }

                isSuggesting = true

                if let location = currentLocation {
                    completerService.setRegion(MKCoordinateRegion(
                        center: location,
                        span: MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5)
                    ))
                }

                completerService.updateQuery(searchQuery)
            } catch {
                // Task cancelled
            }
        }
    }

    @MainActor
    func selectSuggestion(_ suggestion: SearchSuggestion) async {
        showSuggestions = false
        isSearching = true
        errorMessage = nil

        do {
            let places = try await completerService.search(suggestion: suggestion)
            searchResults = places

            if let firstPlace = places.first, places.count == 1 {
                await selectPlace(firstPlace)
            }
        } catch {
            errorMessage = "検索に失敗しました: \(error.localizedDescription)"
            searchResults = []
        }

        isSearching = false
    }

    func hideSuggestions() {
        showSuggestions = false
        debounceTask?.cancel()
    }
}
