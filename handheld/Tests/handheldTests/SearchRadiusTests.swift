import Foundation
import Testing
@testable import handheld

struct SearchRadiusTests {
    // MARK: - rawValue

    @Test func small_rawValue_is3000() {
        #expect(SearchRadius.small.rawValue == 3000)
    }

    @Test func medium_rawValue_is5000() {
        #expect(SearchRadius.medium.rawValue == 5000)
    }

    @Test func large_rawValue_is10000() {
        #expect(SearchRadius.large.rawValue == 10000)
    }

    // MARK: - label

    @Test func small_label_is3km() {
        #expect(SearchRadius.small.label == "3km")
    }

    @Test func medium_label_is5km() {
        #expect(SearchRadius.medium.label == "5km")
    }

    @Test func large_label_is10km() {
        #expect(SearchRadius.large.label == "10km")
    }

    // MARK: - meters

    @Test func small_meters_is3000() {
        #expect(SearchRadius.small.meters == 3000.0)
    }

    @Test func medium_meters_is5000() {
        #expect(SearchRadius.medium.meters == 5000.0)
    }

    @Test func large_meters_is10000() {
        #expect(SearchRadius.large.meters == 10000.0)
    }

    // MARK: - id

    @Test func id_equalsRawValue() {
        #expect(SearchRadius.small.id == 3000)
        #expect(SearchRadius.medium.id == 5000)
        #expect(SearchRadius.large.id == 10000)
    }

    // MARK: - CaseIterable

    @Test func allCases_containsThreeCases() {
        #expect(SearchRadius.allCases.count == 3)
    }

    @Test func allCases_inCorrectOrder() {
        let cases = SearchRadius.allCases
        #expect(cases[0] == .small)
        #expect(cases[1] == .medium)
        #expect(cases[2] == .large)
    }

    // MARK: - Codable

    @Test func codable_encodesAndDecodes() throws {
        let original = SearchRadius.medium
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let data = try encoder.encode(original)
        let decoded = try decoder.decode(SearchRadius.self, from: data)

        #expect(decoded == original)
    }
}
