import Foundation

/// シナリオ統合リクエスト
struct ScenarioIntegrateRequest: Codable, Sendable {
    let scenarios: [SpotScenario]
}
