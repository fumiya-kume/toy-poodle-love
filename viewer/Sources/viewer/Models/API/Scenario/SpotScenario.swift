import Foundation

/// スポットごとのシナリオ
struct SpotScenario: Codable, Identifiable {
    let name: String
    let type: String
    let gemini: String?
    let qwen: String?
    let error: SpotScenarioError?

    var id: String { name + type }

    var bestScenario: String? {
        gemini ?? qwen
    }

    var displayScenario: String {
        if let bestScenario {
            return bestScenario
        }
        if let errorMessage = error?.gemini ?? error?.qwen {
            return errorMessage
        }
        return "シナリオがありません"
    }

    init(
        name: String,
        type: String,
        gemini: String? = nil,
        qwen: String? = nil,
        error: SpotScenarioError? = nil
    ) {
        self.name = name
        self.type = type
        self.gemini = gemini
        self.qwen = qwen
        self.error = error
    }
}

struct SpotScenarioError: Codable {
    let qwen: String?
    let gemini: String?
}
