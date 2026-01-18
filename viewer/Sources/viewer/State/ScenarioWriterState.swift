import Foundation
import Observation

/// Scenario Writer の状態を管理
@Observable
@MainActor
final class ScenarioWriterState {
    // MARK: - ローディング状態

    var isLoadingTextGeneration = false
    var isLoadingGeocode = false
    var isLoadingRouteOptimize = false
    var isLoadingPipeline = false
    var isLoadingRouteGenerate = false
    var isLoadingScenario = false
    var isLoadingScenarioIntegrate = false

    // MARK: - 入力状態

    // テキスト生成
    var textGenerationPrompt = ""
    var selectedTextModel: AIModel = .gemini

    // ジオコーディング
    var geocodeAddresses = ""

    // ルート最適化
    var routeWaypoints: [RouteWaypoint] = []
    var selectedTravelMode: TravelMode = .driving
    var optimizeWaypointOrder = true

    // パイプライン
    var pipelineStartPoint = ""
    var pipelinePurpose = ""
    var pipelineSpotCount: Int = 5
    var pipelineModel: AIModel = .gemini

    // ルート生成
    var routeGenerateStartPoint = ""
    var routeGeneratePurpose = ""
    var routeGenerateSpotCount: Int = 5
    var routeGenerateModel: AIModel = .gemini

    // シナリオ生成
    var scenarioRouteName = ""
    var scenarioLanguage = ""
    var scenarioSpots: [RouteSpot] = []
    var scenarioModels: ScenarioModels = .both

    // MARK: - 結果

    var textGenerationResult: TextGenerationResponse?
    var geocodeResult: GeocodeResponse?
    var routeOptimizeResult: RouteOptimizeResponse?
    var pipelineResult: PipelineResponse?
    var routeGenerateResult: RouteGenerationOutput?
    var scenarioResult: ScenarioOutput?
    var scenarioIntegrationResult: ScenarioIntegrationOutput?

    // MARK: - エラー

    var lastError: APIError?
    var showErrorAlert = false

    // MARK: - API呼び出し

    private let apiClient = APIClient.shared

    // MARK: - テキスト生成

    func generateText() async {
        guard !textGenerationPrompt.isEmpty else { return }

        isLoadingTextGeneration = true
        defer { isLoadingTextGeneration = false }

        switch selectedTextModel {
        case .gemini:
            handleResult(await apiClient.generateTextWithGemini(prompt: textGenerationPrompt)) { result in
                textGenerationResult = result
            }
        case .qwen:
            handleResult(await apiClient.generateTextWithQwen(prompt: textGenerationPrompt)) { result in
                textGenerationResult = result
            }
        }
    }

    // MARK: - ジオコーディング

    func geocode() async {
        let addresses = geocodeAddresses
            .split(separator: "\n")
            .map { String($0).trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        guard !addresses.isEmpty else { return }

        isLoadingGeocode = true
        defer { isLoadingGeocode = false }

        handleResult(await apiClient.geocode(addresses: addresses)) { result in
            geocodeResult = result
        }
    }

    // MARK: - ルート最適化

    func optimizeRoute() async {
        guard !routeWaypoints.isEmpty else { return }

        isLoadingRouteOptimize = true
        defer { isLoadingRouteOptimize = false }

        guard routeWaypoints.count >= 2,
              let origin = routeWaypoints.first,
              let destination = routeWaypoints.last else { return }
        let intermediates = Array(routeWaypoints.dropFirst().dropLast())

        handleResult(
            await apiClient.optimizeRoute(
                origin: origin,
                destination: destination,
                intermediates: intermediates,
                travelMode: selectedTravelMode,
                optimizeWaypointOrder: optimizeWaypointOrder
            )
        ) { result in
            routeOptimizeResult = result
        }
    }

    // MARK: - パイプライン

    func runPipeline() async {
        guard !pipelineStartPoint.isEmpty,
              !pipelinePurpose.isEmpty else { return }

        isLoadingPipeline = true
        defer { isLoadingPipeline = false }

        handleResult(
            await apiClient.pipelineRouteOptimize(
                startPoint: pipelineStartPoint,
                purpose: pipelinePurpose,
                spotCount: pipelineSpotCount,
                model: pipelineModel
            )
        ) { result in
            pipelineResult = result
        }
    }

    // MARK: - ルート生成

    func generateRoute() async {
        guard !routeGenerateStartPoint.isEmpty,
              !routeGeneratePurpose.isEmpty else { return }

        isLoadingRouteGenerate = true
        defer { isLoadingRouteGenerate = false }

        handleResult(
            await apiClient.generateRoute(
                startPoint: routeGenerateStartPoint,
                purpose: routeGeneratePurpose,
                spotCount: routeGenerateSpotCount,
                model: routeGenerateModel
            )
        ) { result in
            routeGenerateResult = result
        }
    }

    // MARK: - シナリオ生成

    func generateScenario() async {
        guard !scenarioRouteName.isEmpty, !scenarioSpots.isEmpty else { return }

        isLoadingScenario = true
        defer { isLoadingScenario = false }

        let language = scenarioLanguage.isEmpty ? nil : scenarioLanguage
        handleResult(
            await apiClient.generateScenario(
                routeName: scenarioRouteName,
                spots: scenarioSpots,
                language: language,
                models: scenarioModels
            )
        ) { result in
            scenarioResult = result
            scenarioIntegrationResult = nil
        }
    }

    // MARK: - シナリオ統合

    func integrateScenarios() async {
        guard let scenarios = scenarioResult?.spots, !scenarios.isEmpty else { return }

        isLoadingScenarioIntegrate = true
        defer { isLoadingScenarioIntegrate = false }

        handleResult(await apiClient.integrateScenario(scenarios: scenarios)) { result in
            scenarioIntegrationResult = result
        }
    }

    // MARK: - ヘルパーメソッド

    /// パイプライン結果からシナリオ用スポットを生成
    func createSpotsFromPipeline() {
        guard let result = pipelineResult else { return }
        let generatedSpots = result.routeGeneration.spots ?? []
        let places = result.geocoding.places ?? []
        if !generatedSpots.isEmpty {
            let placesByName = Dictionary(uniqueKeysWithValues: places.map { ($0.inputAddress, $0) })
            scenarioSpots = generatedSpots.map { spot in
                let matchedPlace = placesByName[spot.name]
                let point = spot.generatedNote ?? matchedPlace?.formattedAddress
                return RouteSpot(
                    name: spot.name,
                    type: RouteSpotType.fromGeneratedType(spot.type),
                    description: spot.description,
                    point: point
                )
            }
        } else if !places.isEmpty {
            scenarioSpots = places.map { place in
                RouteSpot(
                    name: place.inputAddress,
                    type: .waypoint,
                    description: nil,
                    point: place.formattedAddress
                )
            }
        }
        if let routeName = result.routeGeneration.routeName {
            scenarioRouteName = routeName
        }
    }

    /// ルート生成結果からシナリオ用スポットを生成
    func createSpotsFromRouteGeneration() {
        guard let result = routeGenerateResult else { return }
        scenarioSpots = result.spots.map { spot in
            RouteSpot(
                name: spot.name,
                type: RouteSpotType.fromGeneratedType(spot.type),
                description: spot.description,
                point: spot.generatedNote
            )
        }
        if let routeName = result.routeName {
            scenarioRouteName = routeName
        }
    }

    /// ウェイポイントを追加
    func addWaypoint(_ address: String) {
        guard !address.isEmpty else { return }
        routeWaypoints.append(RouteWaypoint(address: address))
    }

    /// ウェイポイントを削除
    func removeWaypoint(at index: Int) {
        guard routeWaypoints.indices.contains(index) else { return }
        routeWaypoints.remove(at: index)
    }

    /// シナリオスポットを追加
    func addScenarioSpot(
        name: String,
        type: RouteSpotType,
        description: String?,
        point: String?
    ) {
        guard !name.isEmpty else { return }
        let normalizedDescription = description?.isEmpty == true ? nil : description
        let normalizedPoint = point?.isEmpty == true ? nil : point
        scenarioSpots.append(
            RouteSpot(
                name: name,
                type: type,
                description: normalizedDescription,
                point: normalizedPoint
            )
        )
    }

    /// シナリオスポットを削除
    func removeScenarioSpot(at index: Int) {
        guard scenarioSpots.indices.contains(index) else { return }
        scenarioSpots.remove(at: index)
    }

    /// 現在表示すべきシナリオリスト（統合版があれば統合版、なければ通常版）
    var displayScenarios: [SpotScenario] {
        scenarioResult?.spots ?? []
    }

    // MARK: - エラーハンドリング

    private func handleError(_ error: APIError) {
        lastError = error
        showErrorAlert = true
    }

    private func handleResult<T>(_ result: Result<T, APIError>, onSuccess: (T) -> Void) {
        switch result {
        case .success(let value):
            onSuccess(value)
        case .failure(let error):
            handleError(error)
        }
    }

    func dismissError() {
        showErrorAlert = false
        lastError = nil
    }
}
