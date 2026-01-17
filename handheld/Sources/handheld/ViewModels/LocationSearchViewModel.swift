import Foundation
import MapKit
import Observation
import os
import SwiftUI

enum LookAroundTarget: String, CaseIterable, Identifiable {
    case destination = "目的地"
    case nextStep = "次の曲がり角"

    var id: String { rawValue }
}

@Observable
@MainActor
final class LocationSearchViewModel {
    var searchQuery: String = ""
    var searchResults: [Place] = []
    var selectedPlace: Place?
    var route: Route?
    var isSearching: Bool = false
    var alertError: AppError?
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

    // ナビゲーションモード
    var isNavigationMode: Bool = false
    var navigationSteps: [NavigationStep] = []
    var currentNavigationStepIndex: Int = 0
    var distanceToNextStep: CLLocationDistance = 0
    var shouldShowNavigationLookAround: Bool = false
    var transportType: TransportType = .automobile

    // 地図操作状態（パフォーマンス最適化用）
    var isUserInteractingWithMap: Bool = false

    // 閾値設定
    let lookAroundTriggerDistance: CLLocationDistance = 200
    let stepCompletionDistance: CLLocationDistance = 30

    // ナビゲーションステップ連続進行防止
    private var lastStepAdvanceTime: Date?
    private let minimumStepDuration: TimeInterval = 5.0

    // AutoDrive関連
    var autoDriveConfiguration = AutoDriveConfiguration()
    var autoDrivePoints: [RouteCoordinatePoint] = []
    var currentAutoDriveIndex: Int = 0
    var showAutoDriveSheet: Bool = false
    private nonisolated(unsafe) var autoDriveTimer: Timer?
    private nonisolated(unsafe) var prefetchTask: Task<Void, Never>?
    private var lastPrefetchedIndex: Int = -1

    let locationManager = LocationManager()
    private let autoDriveService: AutoDriveServiceProtocol = AutoDriveService()

    private let searchService: LocationSearchServiceProtocol
    private let directionsService: DirectionsServiceProtocol
    private let completerService: LocationCompleterServiceProtocol
    private let lookAroundService: LookAroundServiceProtocol
    private let geocodingCacheService: GeocodingCacheService
    private let rateLimiter: RateLimiter
    private nonisolated(unsafe) var debounceTask: Task<Void, Never>?
    private let debounceInterval: Duration = .milliseconds(300)

    init(
        searchService: LocationSearchServiceProtocol = LocationSearchService(),
        directionsService: DirectionsServiceProtocol = DirectionsService(),
        completerService: LocationCompleterServiceProtocol? = nil,
        lookAroundService: LookAroundServiceProtocol = LookAroundService(),
        geocodingCacheService: GeocodingCacheService = GeocodingCacheService(),
        rateLimiter: RateLimiter = RateLimiter()
    ) {
        self.searchService = searchService
        self.directionsService = directionsService
        self.completerService = completerService ?? LocationCompleterService()
        self.lookAroundService = lookAroundService
        self.geocodingCacheService = geocodingCacheService
        self.rateLimiter = rateLimiter
        setupCompleterCallback()
    }

    deinit {
        cleanup()
    }

    /// リソースのクリーンアップ
    private nonisolated func cleanup() {
        autoDriveTimer?.invalidate()
        autoDriveTimer = nil
        prefetchTask?.cancel()
        prefetchTask = nil
        debounceTask?.cancel()
        debounceTask = nil
    }

    private func setupCompleterCallback() {
        completerService.onSuggestionsUpdated = { [weak self] newSuggestions in
            Task { @MainActor in
                self?.suggestions = newSuggestions
                self?.isSuggesting = false
                self?.showSuggestions = !newSuggestions.isEmpty && !(self?.searchQuery.isEmpty ?? true)
                // 距離を非同期で取得
                await self?.fetchDistancesForSuggestions()
            }
        }
    }

    @MainActor
    private func fetchDistancesForSuggestions() async {
        guard let userLocation = currentLocation else { return }

        // 上位10件のみ距離を取得（パフォーマンス考慮）
        let suggestionsToFetch = Array(suggestions.prefix(10))

        await withTaskGroup(of: (UUID, CLLocationCoordinate2D?).self) { group in
            for suggestion in suggestionsToFetch {
                group.addTask {
                    let coordinate = await self.fetchCoordinate(for: suggestion)
                    return (suggestion.id, coordinate)
                }
            }

            for await (id, coordinate) in group {
                guard let coordinate = coordinate,
                      let index = self.suggestions.firstIndex(where: { $0.id == id }) else {
                    continue
                }

                let userCLLocation = CLLocation(
                    latitude: userLocation.latitude,
                    longitude: userLocation.longitude
                )
                let suggestionLocation = CLLocation(
                    latitude: coordinate.latitude,
                    longitude: coordinate.longitude
                )
                let distance = userCLLocation.distance(from: suggestionLocation)

                self.suggestions[index].coordinate = coordinate
                self.suggestions[index].distance = distance
            }
        }
    }

    private func fetchCoordinate(for suggestion: SearchSuggestion) async -> CLLocationCoordinate2D? {
        // 1. キャッシュ確認
        if let cached = await geocodingCacheService.coordinate(
            for: suggestion.title,
            subtitle: suggestion.subtitle
        ) {
            return cached
        }

        // 2. レート制限チェック
        guard await rateLimiter.tryRequest() else {
            AppLogger.cache.warning("レート制限中のためスキップ: \(suggestion.title)")
            return nil
        }

        // 3. API呼び出し
        do {
            let places = try await completerService.search(suggestion: suggestion)
            if let coordinate = places.first?.coordinate {
                // 4. キャッシュに保存
                await geocodingCacheService.cacheCoordinate(
                    coordinate,
                    for: suggestion.title,
                    subtitle: suggestion.subtitle
                )
                return coordinate
            }
            return nil
        } catch {
            AppLogger.search.warning("サジェストの座標取得に失敗しました: \(error.localizedDescription)")
            return nil
        }
    }

    var currentLocation: CLLocationCoordinate2D? {
        locationManager.currentLocation
    }

    var locationErrorMessage: String? {
        locationManager.locationError?.errorDescription
    }

    @MainActor
    func search() async {
        guard !searchQuery.trimmingCharacters(in: .whitespaces).isEmpty else {
            searchResults = []
            return
        }

        isSearching = true
        defer { isSearching = false }
        alertError = nil
        AppLogger.search.info("検索を実行します: \(self.searchQuery, privacy: .private(mask: .hash))")

        do {
            let region: MKCoordinateRegion? = currentLocation.map {
                MKCoordinateRegion(
                    center: $0,
                    span: MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5)
                )
            }
            searchResults = try await searchService.search(query: searchQuery, region: region)
        } catch let error as AppError {
            alertError = error
            searchResults = []
        } catch {
            alertError = .searchFailed(underlying: error)
            searchResults = []
        }
    }

    @MainActor
    func selectPlace(_ place: Place) async {
        AppLogger.search.info("場所を選択しました: \(place.name)")
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
            alertError = .locationUnavailable
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
        } catch let error as AppError {
            alertError = error
        } catch {
            alertError = .routeCalculationFailed(underlying: error)
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
                AppLogger.lookAround.warning("目的地のLook Around取得に失敗しました: \(error.localizedDescription)")
            }
        }

        // 次の曲がり角のLook Aroundを取得
        if let firstStep = route?.steps.first {
            let stepCoordinate = firstStep.polyline.coordinate
            do {
                nextStepLookAroundScene = try await lookAroundService.fetchScene(for: stepCoordinate)
            } catch {
                AppLogger.lookAround.warning("次の曲がり角のLook Around取得に失敗しました: \(error.localizedDescription)")
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
        alertError = nil
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
        alertError = nil
        AppLogger.search.info("サジェストを選択しました: \(suggestion.title)")

        do {
            let places = try await completerService.search(suggestion: suggestion)
            searchResults = places

            if let firstPlace = places.first, places.count == 1 {
                await selectPlace(firstPlace)
            }
        } catch {
            AppLogger.search.error("サジェストからの検索に失敗しました: \(error.localizedDescription)")
            alertError = .searchFailed(underlying: error)
            searchResults = []
        }

        isSearching = false
    }

    func hideSuggestions() {
        showSuggestions = false
        debounceTask?.cancel()
    }

    // MARK: - ナビゲーションモード

    var currentNavigationStep: NavigationStep? {
        guard currentNavigationStepIndex < navigationSteps.count else { return nil }
        return navigationSteps[currentNavigationStepIndex]
    }

    var formattedDistanceToNextStep: String {
        if distanceToNextStep >= 1000 {
            return String(format: "%.1f km", distanceToNextStep / 1000)
        } else {
            return String(format: "%.0f m", distanceToNextStep)
        }
    }

    @MainActor
    func startNavigation() async {
        guard let route = route else { return }

        AppLogger.navigation.info("ナビゲーションを開始しました")
        isNavigationMode = true
        currentNavigationStepIndex = 0
        shouldShowNavigationLookAround = false
        showLookAround = false

        navigationSteps = route.steps.enumerated().map { index, step in
            NavigationStep(step: step, index: index)
        }

        await fetchAllNavigationLookAroundScenes()

        locationManager.startContinuousTracking()
    }

    @MainActor
    func stopNavigation() {
        AppLogger.navigation.info("ナビゲーションを終了しました")
        isNavigationMode = false
        locationManager.stopContinuousTracking()
        navigationSteps = []
        currentNavigationStepIndex = 0
        distanceToNextStep = 0
        shouldShowNavigationLookAround = false
        lastStepAdvanceTime = nil
    }

    @MainActor
    func updateNavigationForLocation(_ location: CLLocationCoordinate2D) {
        guard isNavigationMode, currentNavigationStepIndex < navigationSteps.count else { return }

        let currentStep = navigationSteps[currentNavigationStepIndex]
        distanceToNextStep = location.distance(to: currentStep.coordinate)

        if distanceToNextStep < stepCompletionDistance {
            // 最低滞在時間チェック - 連続進行を防止
            let canAdvance: Bool
            if let lastAdvance = lastStepAdvanceTime {
                canAdvance = Date().timeIntervalSince(lastAdvance) >= minimumStepDuration
            } else {
                canAdvance = true
            }

            if canAdvance {
                advanceToNextStep()
            }
        } else if distanceToNextStep < lookAroundTriggerDistance {
            shouldShowNavigationLookAround = true
        }
    }

    @MainActor
    private func advanceToNextStep() {
        lastStepAdvanceTime = Date()
        currentNavigationStepIndex += 1
        shouldShowNavigationLookAround = false

        if currentNavigationStepIndex >= navigationSteps.count {
            stopNavigation()
        }
    }

    @MainActor
    private func fetchAllNavigationLookAroundScenes() async {
        await lookAroundService.fetchScenesProgressively(for: navigationSteps) { [weak self] index, scene in
            guard let self = self, index < self.navigationSteps.count else { return }
            self.navigationSteps[index].setLookAroundFetchResult(scene)
        }
    }

    @MainActor
    func recalculateRouteWithTransportType() async {
        guard let destination = selectedPlace else { return }
        guard let source = currentLocation else {
            alertError = .locationUnavailable
            return
        }

        do {
            route = try await directionsService.calculateRoute(
                from: source,
                to: destination.coordinate,
                transportType: transportType
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

                await fetchLookAroundScenes()
            }
        } catch let error as AppError {
            alertError = error
        } catch {
            alertError = .routeCalculationFailed(underlying: error)
        }
    }

    // MARK: - AutoDrive

    var currentAutoDriveScene: MKLookAroundScene? {
        guard currentAutoDriveIndex < autoDrivePoints.count else { return nil }
        return autoDrivePoints[currentAutoDriveIndex].lookAroundScene
    }

    var autoDriveTotalPoints: Int {
        autoDrivePoints.count
    }

    var autoDriveProgress: Double {
        guard autoDriveTotalPoints > 1 else { return 0 }
        return Double(currentAutoDriveIndex) / Double(autoDriveTotalPoints - 1)
    }

    @MainActor
    func startAutoDrive() async {
        guard let route = route else { return }

        // 初期化
        autoDrivePoints = autoDriveService.extractDrivePoints(from: route.polyline, interval: 30)
        currentAutoDriveIndex = 0
        lastPrefetchedIndex = -1

        let totalPoints = autoDrivePoints.count
        let initialCount = min(autoDriveConfiguration.initialFetchCount, totalPoints)

        autoDriveConfiguration.state = .initializing(fetchedCount: 0, requiredCount: initialCount)

        // 初期シーン取得（最初の3件を並列取得）
        let successCount = await autoDriveService.fetchInitialScenes(
            for: autoDrivePoints,
            initialCount: initialCount
        ) { [weak self] index, scene in
            guard let self = self, index < self.autoDrivePoints.count else { return }
            self.autoDrivePoints[index].setLookAroundFetchResult(scene)

            let fetchedCount = self.autoDrivePoints.filter { !$0.isLookAroundLoading }.count
            self.autoDriveConfiguration.state = .initializing(fetchedCount: fetchedCount, requiredCount: initialCount)
        }

        // 1件も成功しなかった場合、追加で取得を試みる
        if successCount == 0 {
            let additionalCount = min(3, totalPoints - initialCount)
            if additionalCount > 0 {
                let additionalSuccess = await autoDriveService.fetchInitialScenes(
                    for: Array(autoDrivePoints.dropFirst(initialCount)),
                    initialCount: additionalCount
                ) { [weak self] index, scene in
                    guard let self = self else { return }
                    let actualIndex = initialCount + index
                    if actualIndex < self.autoDrivePoints.count {
                        self.autoDrivePoints[actualIndex].setLookAroundFetchResult(scene)
                    }
                }

                if additionalSuccess == 0 {
                    autoDriveConfiguration.state = .failed(message: "Look Aroundデータが取得できませんでした")
                    return
                }
            } else {
                autoDriveConfiguration.state = .failed(message: "Look Aroundデータが取得できませんでした")
                return
            }
        }

        // 再生開始
        lastPrefetchedIndex = initialCount - 1
        autoDriveConfiguration.state = .playing
        startAutoDriveTimer()
        startPrefetching()
    }

    @MainActor
    func stopAutoDrive() {
        prefetchTask?.cancel()
        prefetchTask = nil
        autoDriveTimer?.invalidate()
        autoDriveTimer = nil
        autoDriveConfiguration.state = .idle
        autoDrivePoints = []
        currentAutoDriveIndex = 0
        lastPrefetchedIndex = -1
    }

    @MainActor
    func pauseAutoDrive() {
        autoDriveTimer?.invalidate()
        autoDriveTimer = nil
        autoDriveConfiguration.state = .paused
    }

    @MainActor
    func resumeAutoDrive() {
        autoDriveConfiguration.state = .playing
        startAutoDriveTimer()
    }

    func setAutoDriveSpeed(_ speed: AutoDriveSpeed) {
        autoDriveConfiguration.speed = speed
        if autoDriveConfiguration.isPlaying {
            autoDriveTimer?.invalidate()
            startAutoDriveTimer()
        }
    }

    @MainActor
    func seekAutoDrive(to index: Int) {
        guard index >= 0 && index < autoDrivePoints.count else { return }
        currentAutoDriveIndex = index
    }

    private func startAutoDriveTimer() {
        autoDriveTimer?.invalidate()
        autoDriveTimer = Timer.scheduledTimer(withTimeInterval: autoDriveConfiguration.speed.intervalSeconds, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.advanceAutoDrive()
            }
        }
    }

    @MainActor
    private func advanceAutoDrive() {
        guard autoDriveConfiguration.isPlaying || autoDriveConfiguration.isBuffering,
              !isUserInteractingWithMap else { return }

        // 次のシーンがある地点を探す
        var nextIndex = currentAutoDriveIndex + 1
        while nextIndex < autoDrivePoints.count {
            let point = autoDrivePoints[nextIndex]

            // シーンがある場合は次へ進む
            if point.lookAroundScene != nil {
                break
            }

            // まだ取得中の場合はバッファリング状態に
            if point.isLookAroundLoading {
                autoDriveConfiguration.state = .buffering
                return
            }

            // 取得失敗の場合はスキップ
            nextIndex += 1
        }

        // バッファリングから復帰 - ユーザー操作中は復帰しない
        if autoDriveConfiguration.isBuffering {
            guard !isUserInteractingWithMap else { return }
            autoDriveConfiguration.state = .playing
        }

        if nextIndex >= autoDrivePoints.count {
            prefetchTask?.cancel()
            prefetchTask = nil
            autoDriveTimer?.invalidate()
            autoDriveTimer = nil
            autoDriveConfiguration.state = .completed
        } else {
            currentAutoDriveIndex = nextIndex
        }
    }

    private func startPrefetching() {
        prefetchTask?.cancel()
        prefetchTask = Task { [weak self] in
            while !Task.isCancelled {
                guard let self = self else { break }

                await self.prefetchAhead()

                // 500msごとにチェック
                try? await Task.sleep(for: .milliseconds(500))
            }
        }
    }

    @MainActor
    private func prefetchAhead() async {
        let currentIndex = currentAutoDriveIndex
        let lookahead = autoDriveConfiguration.prefetchLookahead
        let targetEndIndex = min(currentIndex + lookahead, autoDrivePoints.count)

        // 既にプリフェッチ済みの範囲はスキップ
        let startIndex = max(lastPrefetchedIndex + 1, currentIndex)

        guard startIndex < targetEndIndex else { return }

        await autoDriveService.prefetchScenes(
            for: autoDrivePoints,
            from: startIndex,
            count: targetEndIndex - startIndex
        ) { [weak self] index, scene in
            guard let self = self, index < self.autoDrivePoints.count else { return }
            self.autoDrivePoints[index].setLookAroundFetchResult(scene)
            self.lastPrefetchedIndex = max(self.lastPrefetchedIndex, index)
        }
    }
}
