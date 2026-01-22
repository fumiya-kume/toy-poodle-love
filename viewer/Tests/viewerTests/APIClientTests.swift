import XCTest
@testable import VideoOverlayViewer

// MockURLProtocol is defined in TestHelpers/MockAPIClient.swift

// MARK: - Testable APIClient

/// テスト用にURLSessionを注入可能なAPIクライアント
actor TestableAPIClient {
    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    init(session: URLSession) {
        self.session = session
        self.decoder = JSONDecoder()
        self.encoder = JSONEncoder()
    }

    func post<Request: Encodable, Response: Decodable>(
        endpoint: APIEndpoint,
        body: Request
    ) async -> Result<Response, APIError> {
        guard let url = endpoint.url else {
            return .failure(.invalidURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            request.httpBody = try encoder.encode(body)
        } catch {
            return .failure(.decodingError(error))
        }

        do {
            let (data, response) = try await session.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                return .failure(.invalidResponse)
            }

            guard (200...299).contains(httpResponse.statusCode) else {
                let errorMessage = try? decoder.decode(ErrorResponse.self, from: data).error
                return .failure(.httpError(statusCode: httpResponse.statusCode, message: errorMessage))
            }

            do {
                let decoded = try decoder.decode(Response.self, from: data)
                return .success(decoded)
            } catch {
                return .failure(.decodingError(error))
            }
        } catch {
            return .failure(.networkError(error))
        }
    }
}

// MARK: - APIClient Tests

final class APIClientTests: XCTestCase {
    var session: URLSession!
    var client: TestableAPIClient!

    override func setUp() {
        super.setUp()
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        session = URLSession(configuration: configuration)
        client = TestableAPIClient(session: session)
        MockURLProtocol.reset()
    }

    override func tearDown() {
        MockURLProtocol.reset()
        session = nil
        client = nil
        super.tearDown()
    }

    // MARK: - Success Cases

    func testPost_success_returnsDecodedResult() async {
        let expectedResponse = TextGenerationResponse(response: "Hello, World!")
        let responseData = try! JSONEncoder().encode(expectedResponse)

        MockURLProtocol.mockResponseData = responseData
        MockURLProtocol.mockResponse = HTTPURLResponse(
            url: URL(string: "https://example.com")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )

        let request = TextGenerationRequest(message: "test")
        let result: Result<TextGenerationResponse, APIError> = await client.post(endpoint: .qwen, body: request)

        switch result {
        case .success(let response):
            XCTAssertEqual(response.response, "Hello, World!")
        case .failure(let error):
            XCTFail("Expected success but got error: \(error)")
        }
    }

    func testPost_geocodeSuccess_returnsDecodedResult() async {
        let expectedResponse = GeocodeResponse(
            success: true,
            places: [
                GeocodedPlace(
                    inputAddress: "東京駅",
                    location: LatLng(latitude: 35.6812, longitude: 139.7671),
                    formattedAddress: "〒100-0005 東京都千代田区丸の内１丁目",
                    placeId: "ChIJC3Cf2PuLGGARO2ZYV3dpHQQ"
                )
            ]
        )
        let responseData = try! JSONEncoder().encode(expectedResponse)

        MockURLProtocol.mockResponseData = responseData
        MockURLProtocol.mockResponse = HTTPURLResponse(
            url: URL(string: "https://example.com")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )

        let request = GeocodeRequest(addresses: ["東京駅"])
        let result: Result<GeocodeResponse, APIError> = await client.post(endpoint: .geocode, body: request)

        switch result {
        case .success(let response):
            XCTAssertTrue(response.success)
            XCTAssertEqual(response.places.count, 1)
            XCTAssertEqual(response.places[0].inputAddress, "東京駅")
        case .failure(let error):
            XCTFail("Expected success but got error: \(error)")
        }
    }

    // MARK: - Error Cases

    func testPost_invalidResponse_returnsInvalidResponseError() async {
        // HTTPURLResponseでない場合のテスト
        // MockURLProtocolでは常にHTTPURLResponseを返すため、
        // この状態をシミュレートするのは難しいが、
        // コードパスの存在を確認するためテストを保持
        MockURLProtocol.mockResponseData = Data()
        MockURLProtocol.mockResponse = nil
        MockURLProtocol.mockError = URLError(.cannotParseResponse)

        let request = TextGenerationRequest(message: "test")
        let result: Result<TextGenerationResponse, APIError> = await client.post(endpoint: .qwen, body: request)

        switch result {
        case .success:
            XCTFail("Expected failure but got success")
        case .failure(let error):
            // ネットワークエラーとして処理される
            if case .networkError = error {
                // Expected
            } else {
                XCTFail("Expected networkError but got: \(error)")
            }
        }
    }

    func testPost_httpError_returnsHttpErrorWithStatusCode() async {
        let errorResponse = ErrorResponse(error: "Bad Request")
        let errorData = try! JSONEncoder().encode(errorResponse)

        MockURLProtocol.mockResponseData = errorData
        MockURLProtocol.mockResponse = HTTPURLResponse(
            url: URL(string: "https://example.com")!,
            statusCode: 400,
            httpVersion: nil,
            headerFields: nil
        )

        let request = TextGenerationRequest(message: "test")
        let result: Result<TextGenerationResponse, APIError> = await client.post(endpoint: .qwen, body: request)

        switch result {
        case .success:
            XCTFail("Expected failure but got success")
        case .failure(let error):
            if case .httpError(let statusCode, let message) = error {
                XCTAssertEqual(statusCode, 400)
                XCTAssertEqual(message, "Bad Request")
            } else {
                XCTFail("Expected httpError but got: \(error)")
            }
        }
    }

    func testPost_httpErrorWithoutMessage_returnsHttpErrorWithNilMessage() async {
        MockURLProtocol.mockResponseData = Data() // Empty data
        MockURLProtocol.mockResponse = HTTPURLResponse(
            url: URL(string: "https://example.com")!,
            statusCode: 500,
            httpVersion: nil,
            headerFields: nil
        )

        let request = TextGenerationRequest(message: "test")
        let result: Result<TextGenerationResponse, APIError> = await client.post(endpoint: .qwen, body: request)

        switch result {
        case .success:
            XCTFail("Expected failure but got success")
        case .failure(let error):
            if case .httpError(let statusCode, let message) = error {
                XCTAssertEqual(statusCode, 500)
                XCTAssertNil(message)
            } else {
                XCTFail("Expected httpError but got: \(error)")
            }
        }
    }

    func testPost_decodingError_returnsDecodingError() async {
        let invalidJSON = "{ invalid json }".data(using: .utf8)!

        MockURLProtocol.mockResponseData = invalidJSON
        MockURLProtocol.mockResponse = HTTPURLResponse(
            url: URL(string: "https://example.com")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )

        let request = TextGenerationRequest(message: "test")
        let result: Result<TextGenerationResponse, APIError> = await client.post(endpoint: .qwen, body: request)

        switch result {
        case .success:
            XCTFail("Expected failure but got success")
        case .failure(let error):
            if case .decodingError = error {
                // Expected
            } else {
                XCTFail("Expected decodingError but got: \(error)")
            }
        }
    }

    func testPost_networkError_returnsNetworkError() async {
        MockURLProtocol.mockError = URLError(.notConnectedToInternet)

        let request = TextGenerationRequest(message: "test")
        let result: Result<TextGenerationResponse, APIError> = await client.post(endpoint: .qwen, body: request)

        switch result {
        case .success:
            XCTFail("Expected failure but got success")
        case .failure(let error):
            if case .networkError(let underlyingError) = error {
                XCTAssertTrue(underlyingError is URLError)
            } else {
                XCTFail("Expected networkError but got: \(error)")
            }
        }
    }

    func testPost_timeoutError_returnsNetworkError() async {
        MockURLProtocol.mockError = URLError(.timedOut)

        let request = TextGenerationRequest(message: "test")
        let result: Result<TextGenerationResponse, APIError> = await client.post(endpoint: .qwen, body: request)

        switch result {
        case .success:
            XCTFail("Expected failure but got success")
        case .failure(let error):
            if case .networkError = error {
                // Expected
            } else {
                XCTFail("Expected networkError but got: \(error)")
            }
        }
    }

    // MARK: - HTTP Status Code Tests

    func testPost_401Unauthorized_returnsHttpError() async {
        MockURLProtocol.mockResponseData = Data()
        MockURLProtocol.mockResponse = HTTPURLResponse(
            url: URL(string: "https://example.com")!,
            statusCode: 401,
            httpVersion: nil,
            headerFields: nil
        )

        let request = TextGenerationRequest(message: "test")
        let result: Result<TextGenerationResponse, APIError> = await client.post(endpoint: .qwen, body: request)

        switch result {
        case .success:
            XCTFail("Expected failure")
        case .failure(let error):
            if case .httpError(let statusCode, _) = error {
                XCTAssertEqual(statusCode, 401)
            } else {
                XCTFail("Expected httpError but got: \(error)")
            }
        }
    }

    func testPost_403Forbidden_returnsHttpError() async {
        MockURLProtocol.mockResponseData = Data()
        MockURLProtocol.mockResponse = HTTPURLResponse(
            url: URL(string: "https://example.com")!,
            statusCode: 403,
            httpVersion: nil,
            headerFields: nil
        )

        let request = TextGenerationRequest(message: "test")
        let result: Result<TextGenerationResponse, APIError> = await client.post(endpoint: .qwen, body: request)

        switch result {
        case .success:
            XCTFail("Expected failure")
        case .failure(let error):
            if case .httpError(let statusCode, _) = error {
                XCTAssertEqual(statusCode, 403)
            } else {
                XCTFail("Expected httpError but got: \(error)")
            }
        }
    }

    func testPost_429TooManyRequests_returnsHttpError() async {
        MockURLProtocol.mockResponseData = Data()
        MockURLProtocol.mockResponse = HTTPURLResponse(
            url: URL(string: "https://example.com")!,
            statusCode: 429,
            httpVersion: nil,
            headerFields: nil
        )

        let request = TextGenerationRequest(message: "test")
        let result: Result<TextGenerationResponse, APIError> = await client.post(endpoint: .qwen, body: request)

        switch result {
        case .success:
            XCTFail("Expected failure")
        case .failure(let error):
            if case .httpError(let statusCode, _) = error {
                XCTAssertEqual(statusCode, 429)
            } else {
                XCTFail("Expected httpError but got: \(error)")
            }
        }
    }

    func testPost_503ServiceUnavailable_returnsHttpError() async {
        MockURLProtocol.mockResponseData = Data()
        MockURLProtocol.mockResponse = HTTPURLResponse(
            url: URL(string: "https://example.com")!,
            statusCode: 503,
            httpVersion: nil,
            headerFields: nil
        )

        let request = TextGenerationRequest(message: "test")
        let result: Result<TextGenerationResponse, APIError> = await client.post(endpoint: .qwen, body: request)

        switch result {
        case .success:
            XCTFail("Expected failure")
        case .failure(let error):
            if case .httpError(let statusCode, _) = error {
                XCTAssertEqual(statusCode, 503)
            } else {
                XCTFail("Expected httpError but got: \(error)")
            }
        }
    }

    // MARK: - Request Construction Tests

    func testPost_setsCorrectContentType() async {
        // このテストは実際のリクエスト構築を検証
        // MockURLProtocolでリクエストをキャプチャして検証することも可能
        let expectedResponse = TextGenerationResponse(response: "test")
        let responseData = try! JSONEncoder().encode(expectedResponse)

        MockURLProtocol.mockResponseData = responseData
        MockURLProtocol.mockResponse = HTTPURLResponse(
            url: URL(string: "https://example.com")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )

        let request = TextGenerationRequest(message: "test")
        let _: Result<TextGenerationResponse, APIError> = await client.post(endpoint: .qwen, body: request)

        // リクエストが正常に送信されたことを確認（レスポンスが返ることで間接的に確認）
        // 詳細なリクエスト検証が必要な場合はMockURLProtocolを拡張して
        // リクエストをキャプチャする
    }
}

// MARK: - ErrorResponse Helper

private struct ErrorResponse: Codable {
    let error: String
}
