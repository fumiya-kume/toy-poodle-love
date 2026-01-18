import Foundation

/// シナリオ統合リクエスト
struct ScenarioIntegrateRequest: Codable {
    let scenarios: [SpotScenario]
}
