import MapKit
import Testing
@testable import handheld

struct TransportTypeTests {
    // MARK: - Raw Value Tests

    @Test func walking_hasCorrectRawValue() {
        #expect(TransportType.walking.rawValue == "walking")
    }

    @Test func automobile_hasCorrectRawValue() {
        #expect(TransportType.automobile.rawValue == "automobile")
    }

    // MARK: - Identifiable Tests

    @Test func walking_idMatchesRawValue() {
        #expect(TransportType.walking.id == "walking")
    }

    @Test func automobile_idMatchesRawValue() {
        #expect(TransportType.automobile.id == "automobile")
    }

    // MARK: - MKTransportType Conversion Tests

    @Test func walking_convertsToMKWalking() {
        #expect(TransportType.walking.mkTransportType == .walking)
    }

    @Test func automobile_convertsToMKAutomobile() {
        #expect(TransportType.automobile.mkTransportType == .automobile)
    }

    // MARK: - Icon Tests

    @Test func walking_hasCorrectIcon() {
        #expect(TransportType.walking.icon == "figure.walk")
    }

    @Test func automobile_hasCorrectIcon() {
        #expect(TransportType.automobile.icon == "car.fill")
    }

    // MARK: - Label Tests

    @Test func walking_hasCorrectLabel() {
        #expect(TransportType.walking.label == "徒歩")
    }

    @Test func automobile_hasCorrectLabel() {
        #expect(TransportType.automobile.label == "車")
    }

    // MARK: - CaseIterable Tests

    @Test func allCases_containsBothTypes() {
        #expect(TransportType.allCases.count == 2)
        #expect(TransportType.allCases.contains(.walking))
        #expect(TransportType.allCases.contains(.automobile))
    }
}
