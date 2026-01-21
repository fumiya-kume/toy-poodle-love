import Foundation
@testable import VideoOverlayViewer

/// APIClient のモック実装（テスト用）
actor MockAPIClient {
    var shouldSucceed = true
    var mockResponseData: Data?
    var mockError: APIError?
    var requestHistory: [(endpoint: APIEndpoint, body: Data)] = []

    func reset() {
        shouldSucceed = true
        mockResponseData = nil
        mockError = nil
        requestHistory = []
    }

    func setMockResponse<T: Encodable>(_ response: T) throws {
        mockResponseData = try JSONEncoder().encode(response)
        shouldSucceed = true
        mockError = nil
    }

    func setMockError(_ error: APIError) {
        mockError = error
        shouldSucceed = false
    }

    func recordRequest(endpoint: APIEndpoint, body: Data) {
        requestHistory.append((endpoint: endpoint, body: body))
    }

    var lastRequest: (endpoint: APIEndpoint, body: Data)? {
        requestHistory.last
    }

    var requestCount: Int {
        requestHistory.count
    }
}

/// URLProtocol を使ったネットワークモック
class MockURLProtocol: URLProtocol {
    static var mockResponse: (Data?, URLResponse?, Error?)?

    override class func canInit(with request: URLRequest) -> Bool {
        true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        if let (data, response, error) = MockURLProtocol.mockResponse {
            if let error = error {
                client?.urlProtocol(self, didFailWithError: error)
            } else {
                if let response = response {
                    client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
                }
                if let data = data {
                    client?.urlProtocol(self, didLoad: data)
                }
                client?.urlProtocolDidFinishLoading(self)
            }
        }
    }

    override func stopLoading() {}

    static func setMockResponse(data: Data?, statusCode: Int, error: Error? = nil) {
        let response = HTTPURLResponse(
            url: URL(string: "https://example.com")!,
            statusCode: statusCode,
            httpVersion: nil,
            headerFields: nil
        )
        mockResponse = (data, response, error)
    }

    static func reset() {
        mockResponse = nil
    }
}
