import Foundation

/// 単一スポットシナリオレスポンス
struct SpotScenarioResponse: Codable {
    let scenario: String
    let model: String?
}
