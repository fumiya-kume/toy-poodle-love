import Foundation

/// API呼び出し時に発生するエラー
enum APIError: LocalizedError, Sendable {
    case invalidURL
    case invalidResponse
    case httpError(statusCode: Int, message: String?)
    case decodingError(Error)
    case networkError(Error)
    case serverError(String)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "無効なURLです"
        case .invalidResponse:
            return "サーバーからの応答が無効です"
        case .httpError(let statusCode, let message):
            if let message = message {
                return "HTTPエラー \(statusCode): \(message)"
            }
            return "HTTPエラー \(statusCode)"
        case .decodingError(let error):
            return "データの解析に失敗しました: \(error.localizedDescription)"
        case .networkError(let error):
            return "ネットワークエラー: \(error.localizedDescription)"
        case .serverError(let message):
            return "サーバーエラー: \(message)"
        }
    }
}
