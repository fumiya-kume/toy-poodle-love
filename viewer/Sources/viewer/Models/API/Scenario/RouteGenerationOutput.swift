import Foundation

/// ルート生成APIレスポンス（ラッパー）
struct RouteGenerationResponse: Codable {
    let success: Bool
    let data: RouteGenerationOutput?
    let error: String?
}

/// ルート生成結果データ
struct RouteGenerationOutput: Codable {
    /// 生成日時
    let generatedAt: String?
    /// 生成されたルート名
    let routeName: String?
    /// 生成されたスポット
    let spots: [GeneratedRouteSpot]
    /// 使用したモデル
    let model: String?
    /// 処理時間（ミリ秒）
    let processingTimeMs: Int?
}
