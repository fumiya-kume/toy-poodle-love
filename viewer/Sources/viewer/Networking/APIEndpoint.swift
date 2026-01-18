import Foundation

/// Taxi Scenario Writer API のエンドポイント定義
enum APIEndpoint {
    // AI生成
    case qwen
    case gemini

    // Places
    case geocode

    // Routes
    case routeOptimize

    // Pipeline
    case pipelineRouteOptimize

    // Scenario
    case routeGenerate
    case scenario
    case scenarioSpot
    case scenarioIntegrate

    private static let baseURL = "https://toy-poodle-lover.vercel.app"

    var path: String {
        switch self {
        case .qwen:
            return "/api/qwen"
        case .gemini:
            return "/api/gemini"
        case .geocode:
            return "/api/places/geocode"
        case .routeOptimize:
            return "/api/routes/optimize"
        case .pipelineRouteOptimize:
            return "/api/pipeline/route-optimize"
        case .routeGenerate:
            return "/api/route/generate"
        case .scenario:
            return "/api/scenario"
        case .scenarioSpot:
            return "/api/scenario/spot"
        case .scenarioIntegrate:
            return "/api/scenario/integrate"
        }
    }

    var url: URL? {
        URL(string: Self.baseURL + path)
    }

    var method: String {
        "POST"
    }
}
