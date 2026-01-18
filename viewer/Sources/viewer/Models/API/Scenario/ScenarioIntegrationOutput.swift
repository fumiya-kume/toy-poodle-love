import Foundation

/// シナリオ統合レスポンス
struct ScenarioIntegrationOutput: Codable {
    let integratedAt: String
    let routeName: String
    let sourceModel: String
    let integrationLLM: String
    let integratedScript: String
    let processingTimeMs: Int
}
