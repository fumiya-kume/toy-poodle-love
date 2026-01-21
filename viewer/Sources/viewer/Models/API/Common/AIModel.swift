import Foundation

/// 使用可能なAIモデル
enum AIModel: String, Codable, CaseIterable, Identifiable, Sendable {
    case gemini
    case qwen

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .gemini:
            return "Gemini"
        case .qwen:
            return "Qwen"
        }
    }
}

extension AIModel {
    func toScenarioModels() -> ScenarioModels {
        switch self {
        case .gemini:
            return .gemini
        case .qwen:
            return .qwen
        }
    }
}
