import Foundation

/// テキスト生成リクエスト
struct TextGenerationRequest: Codable, Sendable {
    let message: String
}
