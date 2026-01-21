import Foundation

/// ルート生成入力パラメータ
struct RouteGenerateInput: Codable, Sendable {
    /// スタート地点（例: 東京駅）
    let startPoint: String
    /// 目的・テーマ（例: 皇居周辺を観光したい）
    let purpose: String
    /// 生成する地点数（3-8）
    let spotCount: Int
    /// 使用するAIモデル
    let model: AIModel
}

/// ルート生成リクエスト
struct RouteGenerateRequest: Codable, Sendable {
    let input: RouteGenerateInput
}
