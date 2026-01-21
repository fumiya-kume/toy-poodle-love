import Foundation

/// APIエラーレスポンス
struct ErrorResponse: Codable, Sendable {
    let error: String
}
