import Foundation

/// 単一スポットシナリオリクエスト
struct SpotScenarioRequest: Codable, Sendable {
    let routeName: String
    let spotName: String
    let description: String?
    let point: String?
    let models: ScenarioModels
}
