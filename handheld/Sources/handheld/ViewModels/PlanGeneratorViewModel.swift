import Foundation
import MapKit
import Observation
import SwiftData
import os

enum PlanGeneratorStep: Int, CaseIterable {
    case location = 0
    case category = 1
    case theme = 2
    case confirm = 3

    var title: String {
        switch self {
        case .location: return "エリア選択"
        case .category: return "カテゴリ選択"
        case .theme: return "テーマ設定"
        case .confirm: return "確認"
        }
    }

    var isFirst: Bool { self == .location }
    var isLast: Bool { self == .confirm }
}

enum PlanGeneratorState: Equatable {
    case idle
    case searchingSpots
    case generatingPlan
    case calculatingRoutes
    case completed
    case error(message: String)

    var progressMessage: String {
        switch self {
        case .idle: return ""
        case .searchingSpots: return "スポット検索中..."
        case .generatingPlan: return "AI生成中..."
        case .calculatingRoutes: return "ルート計算中..."
        case .completed: return "完了"
        case .error(let message): return message
        }
    }

    var progressStep: Int {
        switch self {
        case .idle: return 0
        case .searchingSpots: return 1
        case .generatingPlan: return 2
        case .calculatingRoutes: return 3
        case .completed: return 3
        case .error: return 0
        }
    }
}

@Observable
final class PlanGeneratorViewModel {
    // MARK: - Input State
    var currentStep: PlanGeneratorStep = .location
    var locationQuery: String = ""
    var selectedLocation: Place?
    var searchRadius: SearchRadius = .large
    var selectedCategories: Set<PlanCategory> = []
    var theme: String = ""
    var startTime: Date?
    var useStartTime: Bool = false

    // MARK: - Search State
    var locationSuggestions: [Place] = []
    var isSearchingLocation: Bool = false

    // MARK: - Generation State
    var generatorState: PlanGeneratorState = .idle
    var candidatePlaces: [Place] = []
    var generatedPlan: SightseeingPlan?
    var generatedSpots: [PlanSpot] = []
    var spotRoutes: [SpotRoute] = []

    // MARK: - Result View State
    enum ViewMode: String, CaseIterable, Identifiable {
        case timeline = "タイムライン"
        case map = "地図"
        case list = "リスト"

        var id: String { rawValue }

        var icon: String {
            switch self {
            case .timeline: return "clock"
            case .map: return "map"
            case .list: return "list.bullet"
            }
        }
    }
    var viewMode: ViewMode = .timeline
    var selectedSpotForDetail: PlanSpot?
    var showSpotDetailSheet: Bool = false
    var showAddSpotSheet: Bool = false
    var isEditingTitle: Bool = false
    var editedTitle: String = ""

    // MARK: - Services
    private let locationSearchService: LocationSearchServiceProtocol
    private let spotSearchService: SpotSearchServiceProtocol
    private let planRouteService: PlanRouteServiceProtocol
    private let planGeneratorService: PlanGeneratorServiceProtocol
    private let completerService: LocationCompleterServiceProtocol

    var isAIAvailable: Bool {
        planGeneratorService.isAvailable
    }

    init(
        locationSearchService: LocationSearchServiceProtocol = LocationSearchService(),
        spotSearchService: SpotSearchServiceProtocol = SpotSearchService(),
        planRouteService: PlanRouteServiceProtocol = PlanRouteService(),
        planGeneratorService: PlanGeneratorServiceProtocol = PlanGeneratorService(),
        completerService: LocationCompleterServiceProtocol = LocationCompleterService()
    ) {
        self.locationSearchService = locationSearchService
        self.spotSearchService = spotSearchService
        self.planRouteService = planRouteService
        self.planGeneratorService = planGeneratorService
        self.completerService = completerService
    }

    // MARK: - Navigation

    var canProceedToNext: Bool {
        switch currentStep {
        case .location:
            return selectedLocation != nil
        case .category:
            return !selectedCategories.isEmpty
        case .theme:
            return !theme.trimmingCharacters(in: .whitespaces).isEmpty
        case .confirm:
            return true
        }
    }

    func nextStep() {
        guard let next = PlanGeneratorStep(rawValue: currentStep.rawValue + 1) else { return }
        currentStep = next
    }

    func previousStep() {
        guard let prev = PlanGeneratorStep(rawValue: currentStep.rawValue - 1) else { return }
        currentStep = prev
    }

    // MARK: - Location Search

    @MainActor
    func searchLocation() async {
        guard !locationQuery.trimmingCharacters(in: .whitespaces).isEmpty else {
            locationSuggestions = []
            return
        }

        isSearchingLocation = true

        do {
            locationSuggestions = try await locationSearchService.search(query: locationQuery, region: nil)
        } catch {
            AppLogger.search.error("エリア検索に失敗: \(error.localizedDescription)")
            locationSuggestions = []
        }

        isSearchingLocation = false
    }

    func selectLocation(_ place: Place) {
        selectedLocation = place
        locationQuery = place.name
        locationSuggestions = []
    }

    // MARK: - Category Selection

    func toggleCategory(_ category: PlanCategory) {
        if selectedCategories.contains(category) {
            selectedCategories.remove(category)
        } else {
            selectedCategories.insert(category)
        }
    }

    var availableSuggestions: [String] {
        var suggestions: [String] = []
        for category in selectedCategories {
            suggestions.append(contentsOf: category.suggestions)
        }
        return suggestions
    }

    func selectThemeSuggestion(_ suggestion: String) {
        theme = suggestion
    }

    // MARK: - Plan Generation

    @MainActor
    func generatePlan() async {
        guard let location = selectedLocation else { return }

        generatorState = .searchingSpots

        do {
            candidatePlaces = try await spotSearchService.searchSpots(
                theme: theme,
                categories: Array(selectedCategories),
                centerCoordinate: location.coordinate,
                radius: searchRadius
            )

            guard candidatePlaces.count >= 3 else {
                generatorState = .error(message: "候補地が不足しています（\(candidatePlaces.count)件）。範囲を広げてお試しください。")
                return
            }

            generatorState = .generatingPlan

            let generated = try await planGeneratorService.generatePlan(
                theme: theme,
                categories: Array(selectedCategories),
                candidatePlaces: candidatePlaces
            )

            let matchedSpots = planGeneratorService.matchGeneratedSpotsWithPlaces(
                generatedSpots: generated.spots,
                candidatePlaces: candidatePlaces
            )

            guard !matchedSpots.isEmpty else {
                generatorState = .error(message: "スポットのマッチングに失敗しました。再度お試しください。")
                return
            }

            generatedSpots = matchedSpots.enumerated().map { index, matched in
                PlanSpot(
                    order: index,
                    name: matched.place.name,
                    address: matched.place.address,
                    coordinate: matched.place.coordinate,
                    aiDescription: matched.spot.description,
                    estimatedStayDuration: TimeInterval(matched.spot.stayMinutes * 60)
                )
            }

            generatorState = .calculatingRoutes

            spotRoutes = try await planRouteService.calculateRoutes(for: generatedSpots)

            planRouteService.updateSpotRouteInfo(spots: &generatedSpots, routes: spotRoutes)

            let (totalDistance, totalDuration) = planRouteService.calculateTotalMetrics(
                from: spotRoutes,
                spots: generatedSpots
            )

            generatedPlan = SightseeingPlan(
                title: generated.title,
                theme: theme,
                categories: Array(selectedCategories),
                searchRadius: searchRadius,
                centerCoordinate: location.coordinate,
                startTime: useStartTime ? startTime : nil,
                spots: generatedSpots
            )
            generatedPlan?.totalDistance = totalDistance
            generatedPlan?.totalDuration = totalDuration

            generatorState = .completed

        } catch let error as PlanGeneratorError {
            generatorState = .error(message: error.errorDescription ?? "不明なエラー")
        } catch {
            AppLogger.ai.error("プラン生成に失敗: \(error.localizedDescription)")
            generatorState = .error(message: "プラン生成に失敗しました: \(error.localizedDescription)")
        }
    }

    // MARK: - Editing

    func reorderSpots(from source: IndexSet, to destination: Int) {
        generatedSpots.move(fromOffsets: source, toOffset: destination)
        updateSpotOrders()
    }

    func deleteSpot(at offsets: IndexSet) {
        generatedSpots.remove(atOffsets: offsets)
        updateSpotOrders()
    }

    func deleteSpot(_ spot: PlanSpot) {
        if let index = generatedSpots.firstIndex(where: { $0.id == spot.id }) {
            generatedSpots.remove(at: index)
            updateSpotOrders()
        }
    }

    private func updateSpotOrders() {
        for (index, _) in generatedSpots.enumerated() {
            generatedSpots[index].order = index
        }
    }

    func updateStayDuration(for spot: PlanSpot, by minutes: Int) {
        guard let index = generatedSpots.firstIndex(where: { $0.id == spot.id }) else { return }
        let newDuration = generatedSpots[index].estimatedStayDuration + TimeInterval(minutes * 60)
        if newDuration >= 15 * 60 && newDuration <= 180 * 60 {
            generatedSpots[index].estimatedStayDuration = newDuration
        }
    }

    func toggleFavorite(for spot: PlanSpot) {
        guard let index = generatedSpots.firstIndex(where: { $0.id == spot.id }) else { return }
        generatedSpots[index].isFavorite.toggle()
    }

    func startEditingTitle() {
        editedTitle = generatedPlan?.title ?? ""
        isEditingTitle = true
    }

    func saveTitle() {
        generatedPlan?.title = editedTitle
        isEditingTitle = false
    }

    func showSpotDetail(_ spot: PlanSpot) {
        selectedSpotForDetail = spot
        showSpotDetailSheet = true
    }

    // MARK: - Add Spot

    func addSpot(_ place: Place) {
        let newSpot = PlanSpot(
            order: generatedSpots.count,
            name: place.name,
            address: place.address,
            coordinate: place.coordinate,
            aiDescription: "",
            estimatedStayDuration: 30 * 60
        )
        generatedSpots.append(newSpot)
        showAddSpotSheet = false
    }

    // MARK: - Recalculate Routes

    @MainActor
    func recalculateRoutes() async {
        generatorState = .calculatingRoutes

        do {
            spotRoutes = try await planRouteService.calculateRoutes(for: generatedSpots)
            planRouteService.updateSpotRouteInfo(spots: &generatedSpots, routes: spotRoutes)

            let (totalDistance, totalDuration) = planRouteService.calculateTotalMetrics(
                from: spotRoutes,
                spots: generatedSpots
            )
            generatedPlan?.totalDistance = totalDistance
            generatedPlan?.totalDuration = totalDuration

            generatorState = .completed
        } catch {
            generatorState = .error(message: "ルート再計算に失敗しました")
        }
    }

    // MARK: - Save

    @MainActor
    func savePlan(context: ModelContext) {
        guard let plan = generatedPlan else { return }

        plan.spots = generatedSpots
        plan.updatedAt = Date()

        context.insert(plan)

        do {
            try context.save()
            AppLogger.data.info("プランを保存しました: \(plan.title)")
        } catch {
            AppLogger.data.error("プランの保存に失敗: \(error.localizedDescription)")
        }
    }

    func saveFavoriteSpots(context: ModelContext) {
        let favoriteSpots = generatedSpots.filter { $0.isFavorite }

        for spot in favoriteSpots {
            let favoriteSpot = FavoriteSpot(from: spot)
            context.insert(favoriteSpot)
        }

        do {
            try context.save()
            AppLogger.data.info("お気に入りスポットを保存しました: \(favoriteSpots.count)件")
        } catch {
            AppLogger.data.error("お気に入りスポットの保存に失敗: \(error.localizedDescription)")
        }
    }

    // MARK: - Reset

    func reset() {
        currentStep = .location
        locationQuery = ""
        selectedLocation = nil
        searchRadius = .large
        selectedCategories = []
        theme = ""
        startTime = nil
        useStartTime = false
        generatorState = .idle
        candidatePlaces = []
        generatedPlan = nil
        generatedSpots = []
        spotRoutes = []
        viewMode = .timeline
    }

    // MARK: - Share

    func openInAppleMaps() {
        guard !generatedSpots.isEmpty else { return }

        var urlString = "maps://?"

        let destinations = generatedSpots.map { spot in
            "\(spot.latitude),\(spot.longitude)"
        }.joined(separator: "&daddr=")

        urlString += "daddr=\(destinations)&dirflg=d"

        if let url = URL(string: urlString) {
            #if os(iOS)
            UIApplication.shared.open(url)
            #endif
        }
    }

    // MARK: - Polylines for Map

    var routePolylines: [MKPolyline] {
        spotRoutes.map { $0.route.polyline }
    }
}
