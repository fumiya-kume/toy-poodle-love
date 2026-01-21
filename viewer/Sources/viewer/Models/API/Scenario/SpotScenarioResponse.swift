import Foundation

/// 単一スポットシナリオレスポンス
struct SpotScenarioResponse: Codable, Sendable {
    let scenario: String
    let model: String?
}
