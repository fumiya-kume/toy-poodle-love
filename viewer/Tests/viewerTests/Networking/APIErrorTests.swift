import Foundation
import Testing
@testable import VideoOverlayViewer

struct APIErrorTests {
    // MARK: - Error Description Tests

    @Test func invalidURL_hasCorrectDescription() {
        let error = APIError.invalidURL
        #expect(error.errorDescription == "無効なURLです")
    }

    @Test func invalidResponse_hasCorrectDescription() {
        let error = APIError.invalidResponse
        #expect(error.errorDescription == "サーバーからの応答が無効です")
    }

    @Test func httpError_withStatusCodeOnly_includesStatusCode() {
        let error = APIError.httpError(statusCode: 404, message: nil)
        #expect(error.errorDescription == "HTTPエラー 404")
    }

    @Test func httpError_withMessage_includesStatusCodeAndMessage() {
        let error = APIError.httpError(statusCode: 400, message: "Bad Request")
        #expect(error.errorDescription == "HTTPエラー 400: Bad Request")
    }

    @Test func httpError_with500_formatsCorrectly() {
        let error = APIError.httpError(statusCode: 500, message: "Internal Server Error")
        #expect(error.errorDescription == "HTTPエラー 500: Internal Server Error")
    }

    @Test func httpError_withJapaneseMessage_includesJapaneseText() {
        let error = APIError.httpError(statusCode: 403, message: "アクセスが拒否されました")
        #expect(error.errorDescription?.contains("アクセスが拒否されました") == true)
    }

    @Test func decodingError_includesErrorDetails() {
        struct TestError: Error, LocalizedError {
            var errorDescription: String? { "JSON parse error" }
        }
        let error = APIError.decodingError(TestError())
        #expect(error.errorDescription?.contains("データの解析に失敗しました") == true)
    }

    @Test func networkError_includesErrorDetails() {
        struct TestNetworkError: Error, LocalizedError {
            var errorDescription: String? { "Connection timeout" }
        }
        let error = APIError.networkError(TestNetworkError())
        #expect(error.errorDescription?.contains("ネットワークエラー") == true)
    }

    @Test func serverError_includesMessage() {
        let error = APIError.serverError("サーバーが応答していません")
        #expect(error.errorDescription == "サーバーエラー: サーバーが応答していません")
    }

    @Test func serverError_withEmptyMessage_formatsCorrectly() {
        let error = APIError.serverError("")
        #expect(error.errorDescription == "サーバーエラー: ")
    }

    // MARK: - Error Description Non-nil Tests

    @Test func allErrors_haveNonNilDescription() {
        let errors: [APIError] = [
            .invalidURL,
            .invalidResponse,
            .httpError(statusCode: 404, message: nil),
            .httpError(statusCode: 500, message: "Error"),
            .decodingError(NSError(domain: "", code: 0)),
            .networkError(NSError(domain: "", code: 0)),
            .serverError("Test")
        ]

        for error in errors {
            #expect(error.errorDescription != nil)
        }
    }

    // MARK: - Localized Error Conformance

    @Test func invalidURL_conformsToLocalizedError() {
        let error: LocalizedError = APIError.invalidURL
        #expect(error.errorDescription != nil)
    }
}
