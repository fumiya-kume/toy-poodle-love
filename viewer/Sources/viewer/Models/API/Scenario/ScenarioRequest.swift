import Foundation

/// シナリオ生成リクエスト
struct ScenarioRequest: Codable {
    let route: ScenarioRoute
    let models: ScenarioModels
}

struct ScenarioRoute: Codable {
    let routeName: String
    let spots: [RouteSpot]
    let language: String?
}

enum ScenarioModels: String, Codable, CaseIterable, Identifiable {
    case qwen
    case gemini
    case both

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .qwen:
            return "Qwen"
        case .gemini:
            return "Gemini"
        case .both:
            return "両方"
        }
    }
}
