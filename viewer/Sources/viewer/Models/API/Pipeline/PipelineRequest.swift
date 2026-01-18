import Foundation

/// パイプライン（E2Eルート生成〜最適化）リクエスト
struct PipelineRequest: Codable {
    let startPoint: String
    let purpose: String
    let spotCount: Int
    let model: AIModel
}
