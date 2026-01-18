import Foundation

/// API呼び出しを行うHTTPクライアント
actor APIClient {
    static let shared = APIClient()

    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    private init() {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 60
        configuration.timeoutIntervalForResource = 120
        self.session = URLSession(configuration: configuration)

        self.decoder = JSONDecoder()
        self.encoder = JSONEncoder()
    }

    /// 汎用的なPOSTリクエスト
    func post<Request: Encodable, Response: Decodable>(
        endpoint: APIEndpoint,
        body: Request
    ) async -> Result<Response, APIError> {
        guard let url = endpoint.url else {
            return .failure(.invalidURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            request.httpBody = try encoder.encode(body)
        } catch {
            return .failure(.decodingError(error))
        }

        do {
            let (data, response) = try await session.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                return .failure(.invalidResponse)
            }

            guard (200...299).contains(httpResponse.statusCode) else {
                let errorMessage = try? decoder.decode(ErrorResponse.self, from: data).error
                return .failure(.httpError(statusCode: httpResponse.statusCode, message: errorMessage))
            }

            do {
                let decoded = try decoder.decode(Response.self, from: data)
                if let successResponse = decoded as? APISuccessResponse, !successResponse.success {
                    return .failure(.serverError(successResponse.errorMessage ?? "Request failed"))
                }
                return .success(decoded)
            } catch {
                return .failure(.decodingError(error))
            }
        } catch {
            return .failure(.networkError(error))
        }
    }

    // MARK: - AI生成

    func generateTextWithQwen(prompt: String) async -> Result<TextGenerationResponse, APIError> {
        let request = TextGenerationRequest(message: prompt)
        return await post(endpoint: .qwen, body: request)
    }

    func generateTextWithGemini(prompt: String) async -> Result<TextGenerationResponse, APIError> {
        let request = TextGenerationRequest(message: prompt)
        return await post(endpoint: .gemini, body: request)
    }

    // MARK: - Places

    func geocode(addresses: [String]) async -> Result<GeocodeResponse, APIError> {
        let request = GeocodeRequest(addresses: addresses)
        return await post(endpoint: .geocode, body: request)
    }

    // MARK: - Routes

    func optimizeRoute(
        origin: RouteWaypoint,
        destination: RouteWaypoint,
        intermediates: [RouteWaypoint] = [],
        travelMode: TravelMode = .driving,
        optimizeWaypointOrder: Bool = true
    ) async -> Result<RouteOptimizeResponse, APIError> {
        let request = RouteOptimizeRequest(
            origin: origin,
            destination: destination,
            intermediates: intermediates,
            travelMode: travelMode,
            optimizeWaypointOrder: optimizeWaypointOrder
        )
        return await post(endpoint: .routeOptimize, body: request)
    }

    // MARK: - Pipeline

    func pipelineRouteOptimize(
        startPoint: String,
        purpose: String,
        spotCount: Int,
        model: AIModel
    ) async -> Result<PipelineResponse, APIError> {
        let request = PipelineRequest(
            startPoint: startPoint,
            purpose: purpose,
            spotCount: spotCount,
            model: model
        )
        return await post(endpoint: .pipelineRouteOptimize, body: request)
    }

    // MARK: - Scenario

    func generateRoute(
        startPoint: String,
        purpose: String,
        spotCount: Int,
        model: AIModel = .gemini
    ) async -> Result<RouteGenerationOutput, APIError> {
        let input = RouteGenerateInput(
            startPoint: startPoint,
            purpose: purpose,
            spotCount: spotCount,
            model: model
        )
        let request = RouteGenerateRequest(input: input)
        let response: Result<RouteGenerationResponse, APIError> = await post(endpoint: .routeGenerate, body: request)
        return response.flatMap { responseValue in
            guard let data = responseValue.data else {
                return .failure(.serverError("Missing route generation data"))
            }
            return .success(data)
        }
    }

    func generateScenario(
        routeName: String,
        spots: [RouteSpot],
        language: String? = nil,
        models: ScenarioModels = .both
    ) async -> Result<ScenarioOutput, APIError> {
        let route = ScenarioRoute(routeName: routeName, spots: spots, language: language)
        let request = ScenarioRequest(route: route, models: models)
        return await post(endpoint: .scenario, body: request)
    }

    func generateSpotScenario(
        routeName: String,
        spotName: String,
        description: String? = nil,
        point: String? = nil,
        models: ScenarioModels = .gemini
    ) async -> Result<SpotScenarioResponse, APIError> {
        let request = SpotScenarioRequest(
            routeName: routeName,
            spotName: spotName,
            description: description,
            point: point,
            models: models
        )
        return await post(endpoint: .scenarioSpot, body: request)
    }

    func integrateScenario(scenarios: [SpotScenario]) async -> Result<ScenarioIntegrationOutput, APIError> {
        let request = ScenarioIntegrateRequest(scenarios: scenarios)
        return await post(endpoint: .scenarioIntegrate, body: request)
    }
}

private protocol APISuccessResponse {
    var success: Bool { get }
    var errorMessage: String? { get }
}

extension GeocodeResponse: APISuccessResponse {
    var errorMessage: String? { nil }
}

extension RouteOptimizeResponse: APISuccessResponse {
    var errorMessage: String? { nil }
}

extension PipelineResponse: APISuccessResponse {
    var errorMessage: String? { error }
}

extension RouteGenerationResponse: APISuccessResponse {
    var errorMessage: String? { error }
}
