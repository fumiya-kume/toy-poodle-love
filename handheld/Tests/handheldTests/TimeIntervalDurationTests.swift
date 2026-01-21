import Foundation
import Testing
@testable import handheld

// MARK: - TimeInterval+Duration Tests

struct TimeIntervalDurationTests {
    // MARK: - Under 60 minutes

    @Test func formattedDuration_0minutes_showsZeroMinutes() {
        let duration: TimeInterval = 0
        #expect(duration.formattedDuration == "0分")
    }

    @Test func formattedDuration_1minute_showsMinutes() {
        let duration: TimeInterval = 60 // 1 minute
        #expect(duration.formattedDuration == "1分")
    }

    @Test func formattedDuration_30minutes_showsMinutes() {
        let duration: TimeInterval = 30 * 60 // 30 minutes
        #expect(duration.formattedDuration == "30分")
    }

    @Test func formattedDuration_59minutes_showsMinutes() {
        let duration: TimeInterval = 59 * 60 // 59 minutes
        #expect(duration.formattedDuration == "59分")
    }

    // MARK: - Exactly 60 minutes and above

    @Test func formattedDuration_exactly60minutes_showsHoursOnly() {
        let duration: TimeInterval = 60 * 60 // 60 minutes
        #expect(duration.formattedDuration == "1時間")
    }

    @Test func formattedDuration_61minutes_showsHoursAndMinutes() {
        let duration: TimeInterval = 61 * 60 // 61 minutes
        #expect(duration.formattedDuration == "1時間1分")
    }

    @Test func formattedDuration_90minutes_showsHoursAndMinutes() {
        let duration: TimeInterval = 90 * 60 // 90 minutes
        #expect(duration.formattedDuration == "1時間30分")
    }

    @Test func formattedDuration_120minutes_showsHoursOnly() {
        let duration: TimeInterval = 120 * 60 // 120 minutes
        #expect(duration.formattedDuration == "2時間")
    }

    @Test func formattedDuration_135minutes_showsHoursAndMinutes() {
        let duration: TimeInterval = 135 * 60 // 135 minutes
        #expect(duration.formattedDuration == "2時間15分")
    }

    @Test func formattedDuration_180minutes_showsHoursOnly() {
        let duration: TimeInterval = 180 * 60 // 180 minutes
        #expect(duration.formattedDuration == "3時間")
    }

    // MARK: - Edge Cases

    @Test func formattedDuration_59seconds_showsZeroMinutes() {
        let duration: TimeInterval = 59 // Less than 1 minute
        #expect(duration.formattedDuration == "0分")
    }

    @Test func formattedDuration_largeValue_handlesCorrectly() {
        let duration: TimeInterval = 10 * 60 * 60 // 10 hours
        #expect(duration.formattedDuration == "10時間")
    }

    @Test func formattedDuration_10hoursAnd30minutes() {
        let duration: TimeInterval = 10 * 60 * 60 + 30 * 60 // 10 hours 30 minutes
        #expect(duration.formattedDuration == "10時間30分")
    }
}
