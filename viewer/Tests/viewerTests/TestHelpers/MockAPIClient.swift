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
    private final class Storage<T>: @unchecked Sendable {
        private let lock = NSLock()
        private var _value: T?

        var value: T? {
            get {
                lock.lock()
                defer { lock.unlock() }
                return _value
            }
            set {
                lock.lock()
                defer { lock.unlock() }
                _value = newValue
            }
        }
    }

    // Static properties for backward compatibility
    private static let dataStorage = Storage<Data>()
    private static let responseStorage = Storage<HTTPURLResponse>()
    private static let errorStorage = Storage<Error>()

    static var mockResponseData: Data? {
        get { dataStorage.value }
        set { dataStorage.value = newValue }
    }

    static var mockResponse: HTTPURLResponse? {
        get { responseStorage.value }
        set { responseStorage.value = newValue }
    }

    static var mockError: Error? {
        get { errorStorage.value }
        set { errorStorage.value = newValue }
    }

    override class func canInit(with request: URLRequest) -> Bool {
        true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        if let error = Self.mockError {
            client?.urlProtocol(self, didFailWithError: error)
        } else {
            if let response = Self.mockResponse {
                client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            }
            if let data = Self.mockResponseData {
                client?.urlProtocol(self, didLoad: data)
            }
            client?.urlProtocolDidFinishLoading(self)
        }
    }

    override func stopLoading() {}

    static func setMockResponse(data: Data?, statusCode: Int, error: Error? = nil) {
        mockResponseData = data
        mockResponse = HTTPURLResponse(
            url: URL(string: "https://example.com")!,
            statusCode: statusCode,
            httpVersion: nil,
            headerFields: nil
        )
        mockError = error
    }

    static func reset() {
        mockResponseData = nil
        mockResponse = nil
        mockError = nil
    }
}
