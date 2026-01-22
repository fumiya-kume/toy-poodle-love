import XCTest
@testable import VideoOverlayViewer

final class APIErrorTests: XCTestCase {

    // MARK: - invalidURL

    func testInvalidURL_errorDescription_containsExpectedMessage() {
        let error = APIError.invalidURL
        XCTAssertEqual(error.errorDescription, "無効なURLです")
    }

    // MARK: - invalidResponse

    func testInvalidResponse_errorDescription_containsExpectedMessage() {
        let error = APIError.invalidResponse
        XCTAssertEqual(error.errorDescription, "サーバーからの応答が無効です")
    }

    // MARK: - httpError

    func testHttpError_withMessage_includesStatusCodeAndMessage() {
        let error = APIError.httpError(statusCode: 404, message: "Not Found")
        XCTAssertEqual(error.errorDescription, "HTTPエラー 404: Not Found")
    }

    func testHttpError_withoutMessage_includesOnlyStatusCode() {
        let error = APIError.httpError(statusCode: 500, message: nil)
        XCTAssertEqual(error.errorDescription, "HTTPエラー 500")
    }

    func testHttpError_variousStatusCodes() {
        let testCases: [(Int, String?, String)] = [
            (400, "Bad Request", "HTTPエラー 400: Bad Request"),
            (401, "Unauthorized", "HTTPエラー 401: Unauthorized"),
            (403, "Forbidden", "HTTPエラー 403: Forbidden"),
            (429, "Too Many Requests", "HTTPエラー 429: Too Many Requests"),
            (503, nil, "HTTPエラー 503"),
        ]

        for (statusCode, message, expected) in testCases {
            let error = APIError.httpError(statusCode: statusCode, message: message)
            XCTAssertEqual(error.errorDescription, expected, "Status code \(statusCode) failed")
        }
    }

    // MARK: - decodingError

    func testDecodingError_errorDescription_containsUnderlyingError() {
        let underlyingError = NSError(domain: "TestDomain", code: 1, userInfo: [NSLocalizedDescriptionKey: "テストエラー"])
        let error = APIError.decodingError(underlyingError)

        XCTAssertNotNil(error.errorDescription)
        XCTAssertTrue(error.errorDescription!.contains("データの解析に失敗しました"))
        XCTAssertTrue(error.errorDescription!.contains("テストエラー"))
    }

    func testDecodingError_withDecodingError_containsDescription() {
        struct TestStruct: Decodable {
            let value: Int
        }

        let invalidJSON = "{ \"value\": \"not a number\" }".data(using: .utf8)!
        do {
            _ = try JSONDecoder().decode(TestStruct.self, from: invalidJSON)
            XCTFail("Expected decoding to fail")
        } catch {
            let apiError = APIError.decodingError(error)
            XCTAssertNotNil(apiError.errorDescription)
            XCTAssertTrue(apiError.errorDescription!.contains("データの解析に失敗しました"))
        }
    }

    // MARK: - networkError

    func testNetworkError_errorDescription_containsUnderlyingError() {
        let underlyingError = NSError(domain: NSURLErrorDomain, code: NSURLErrorNotConnectedToInternet, userInfo: [NSLocalizedDescriptionKey: "インターネット接続がありません"])
        let error = APIError.networkError(underlyingError)

        XCTAssertNotNil(error.errorDescription)
        XCTAssertTrue(error.errorDescription!.contains("ネットワークエラー"))
        XCTAssertTrue(error.errorDescription!.contains("インターネット接続がありません"))
    }

    func testNetworkError_variousURLErrors() {
        let urlErrors: [(Int, String)] = [
            (NSURLErrorTimedOut, "リクエストがタイムアウトしました"),
            (NSURLErrorCannotConnectToHost, "ホストに接続できません"),
            (NSURLErrorNetworkConnectionLost, "ネットワーク接続が切断されました"),
        ]

        for (code, description) in urlErrors {
            let underlyingError = NSError(domain: NSURLErrorDomain, code: code, userInfo: [NSLocalizedDescriptionKey: description])
            let error = APIError.networkError(underlyingError)

            XCTAssertNotNil(error.errorDescription)
            XCTAssertTrue(error.errorDescription!.contains("ネットワークエラー"))
            XCTAssertTrue(error.errorDescription!.contains(description), "Should contain: \(description)")
        }
    }

    // MARK: - serverError

    func testServerError_errorDescription_containsMessage() {
        let error = APIError.serverError("リクエストの処理に失敗しました")
        XCTAssertEqual(error.errorDescription, "サーバーエラー: リクエストの処理に失敗しました")
    }

    func testServerError_emptyMessage() {
        let error = APIError.serverError("")
        XCTAssertEqual(error.errorDescription, "サーバーエラー: ")
    }

    // MARK: - LocalizedError Conformance

    func testLocalizedError_conformance() {
        let errors: [APIError] = [
            .invalidURL,
            .invalidResponse,
            .httpError(statusCode: 404, message: "Not Found"),
            .decodingError(NSError(domain: "Test", code: 0)),
            .networkError(NSError(domain: "Test", code: 0)),
            .serverError("Test"),
        ]

        for error in errors {
            // LocalizedError conformance ensures errorDescription is accessible
            XCTAssertNotNil(error.errorDescription, "Error \(error) should have errorDescription")
        }
    }
}
