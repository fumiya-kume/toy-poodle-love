import Foundation

/// シナリオ生成レスポンス
struct ScenarioOutput: Codable {
    let generatedAt: String
    let routeName: String
    let spots: [SpotScenario]
    let stats: ScenarioStats
}

struct ScenarioStats: Codable {
    let totalSpots: Int
    let successCount: Int
    let processingTimeMs: Int
}
