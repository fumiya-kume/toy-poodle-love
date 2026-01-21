import CoreLocation
import Foundation
import Testing
@testable import handheld

// MARK: - LocationError Tests

struct LocationErrorTests {
    // MARK: - Error Description Tests

    @Test func locationUnknown_hasCorrectDescription() {
        let error = LocationError.locationUnknown
        #expect(error.errorDescription == "現在地を特定できません。Wi-Fiをオンにして再試行してください")
    }

    @Test func denied_hasCorrectDescription() {
        let error = LocationError.denied
        #expect(error.errorDescription == "位置情報へのアクセスが拒否されています")
    }

    @Test func network_hasCorrectDescription() {
        let error = LocationError.network
        #expect(error.errorDescription == "ネットワークエラーが発生しました")
    }

    @Test func headingFailure_hasCorrectDescription() {
        let error = LocationError.headingFailure
        #expect(error.errorDescription == "方位を取得できません")
    }

    @Test func unknown_includesUnderlyingErrorDescription() {
        let underlyingError = NSError(
            domain: "TestDomain",
            code: 999,
            userInfo: [NSLocalizedDescriptionKey: "テストエラー"]
        )
        let error = LocationError.unknown(underlyingError)
        #expect(error.errorDescription == "テストエラー")
    }

    // MARK: - isRetryable Tests

    @Test func locationUnknown_isRetryable() {
        let error = LocationError.locationUnknown
        #expect(error.isRetryable == true)
    }

    @Test func network_isRetryable() {
        let error = LocationError.network
        #expect(error.isRetryable == true)
    }

    @Test func denied_isNotRetryable() {
        let error = LocationError.denied
        #expect(error.isRetryable == false)
    }

    @Test func headingFailure_isNotRetryable() {
        let error = LocationError.headingFailure
        #expect(error.isRetryable == false)
    }

    @Test func unknown_isNotRetryable() {
        let underlyingError = NSError(domain: "TestDomain", code: 999)
        let error = LocationError.unknown(underlyingError)
        #expect(error.isRetryable == false)
    }

    // MARK: - from() Factory Method Tests

    @Test func from_locationUnknownError_returnsLocationUnknown() {
        let clError = NSError(domain: kCLErrorDomain, code: CLError.Code.locationUnknown.rawValue)
        let result = LocationError.from(clError)
        #expect(result == .locationUnknown)
    }

    @Test func from_deniedError_returnsDenied() {
        let clError = NSError(domain: kCLErrorDomain, code: CLError.Code.denied.rawValue)
        let result = LocationError.from(clError)
        #expect(result == .denied)
    }

    @Test func from_networkError_returnsNetwork() {
        let clError = NSError(domain: kCLErrorDomain, code: CLError.Code.network.rawValue)
        let result = LocationError.from(clError)
        #expect(result == .network)
    }

    @Test func from_headingFailureError_returnsHeadingFailure() {
        let clError = NSError(domain: kCLErrorDomain, code: CLError.Code.headingFailure.rawValue)
        let result = LocationError.from(clError)
        #expect(result == .headingFailure)
    }

    @Test func from_nonCLErrorDomain_returnsUnknown() {
        let error = NSError(domain: "DifferentDomain", code: 1)
        let result = LocationError.from(error)
        if case .unknown(let underlyingError) = result {
            #expect((underlyingError as NSError).domain == "DifferentDomain")
        } else {
            Issue.record("Expected .unknown case")
        }
    }

    @Test func from_unknownCLErrorCode_returnsUnknown() {
        let clError = NSError(domain: kCLErrorDomain, code: 9999)
        let result = LocationError.from(clError)
        if case .unknown = result {
            // Success
        } else {
            Issue.record("Expected .unknown case")
        }
    }

    // MARK: - Equatable Tests

    @Test func locationUnknown_equalsItself() {
        #expect(LocationError.locationUnknown == LocationError.locationUnknown)
    }

    @Test func denied_equalsItself() {
        #expect(LocationError.denied == LocationError.denied)
    }

    @Test func network_equalsItself() {
        #expect(LocationError.network == LocationError.network)
    }

    @Test func headingFailure_equalsItself() {
        #expect(LocationError.headingFailure == LocationError.headingFailure)
    }

    @Test func locationUnknown_doesNotEqualDenied() {
        #expect(LocationError.locationUnknown != LocationError.denied)
    }

    @Test func network_doesNotEqualHeadingFailure() {
        #expect(LocationError.network != LocationError.headingFailure)
    }
}

// MARK: - LocationError Equatable Extension for Testing

extension LocationError: @retroactive Equatable {
    public static func == (lhs: LocationError, rhs: LocationError) -> Bool {
        switch (lhs, rhs) {
        case (.locationUnknown, .locationUnknown),
             (.denied, .denied),
             (.network, .network),
             (.headingFailure, .headingFailure):
            return true
        case (.unknown, .unknown):
            return true
        default:
            return false
        }
    }
}
