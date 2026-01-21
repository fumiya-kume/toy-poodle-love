import AVFoundation
import Testing
@testable import VideoOverlayViewer

struct CMTimeFormattingTests {
    // MARK: - formattedString Tests

    @Test func formattedString_withZeroTime_returnsZeroMinutes() {
        let time = CMTime.zero
        #expect(time.formattedString == "0:00")
    }

    @Test func formattedString_withSecondsOnly_formatsCorrectly() {
        let time = CMTime(seconds: 45, preferredTimescale: 600)
        #expect(time.formattedString == "0:45")
    }

    @Test func formattedString_withMinutesAndSeconds_formatsCorrectly() {
        let time = CMTime(seconds: 125, preferredTimescale: 600) // 2:05
        #expect(time.formattedString == "2:05")
    }

    @Test func formattedString_withExactMinutes_formatsCorrectly() {
        let time = CMTime(seconds: 120, preferredTimescale: 600) // 2:00
        #expect(time.formattedString == "2:00")
    }

    @Test func formattedString_withHours_includesHours() {
        let time = CMTime(seconds: 3725, preferredTimescale: 600) // 1:02:05
        #expect(time.formattedString == "1:02:05")
    }

    @Test func formattedString_withExactHour_formatsCorrectly() {
        let time = CMTime(seconds: 3600, preferredTimescale: 600) // 1:00:00
        #expect(time.formattedString == "1:00:00")
    }

    @Test func formattedString_withInvalidTime_returnsDashes() {
        let time = CMTime.invalid
        #expect(time.formattedString == "--:--")
    }

    @Test func formattedString_withIndefiniteTime_returnsDashes() {
        let time = CMTime.indefinite
        #expect(time.formattedString == "--:--")
    }

    // MARK: - shortFormattedString Tests

    @Test func shortFormattedString_withZeroTime_returnsZeroMinutes() {
        let time = CMTime.zero
        #expect(time.shortFormattedString == "0:00")
    }

    @Test func shortFormattedString_withSecondsOnly_formatsCorrectly() {
        let time = CMTime(seconds: 45, preferredTimescale: 600)
        #expect(time.shortFormattedString == "0:45")
    }

    @Test func shortFormattedString_withMinutesAndSeconds_formatsCorrectly() {
        let time = CMTime(seconds: 125, preferredTimescale: 600) // 2:05
        #expect(time.shortFormattedString == "2:05")
    }

    @Test func shortFormattedString_withLargeMinutes_formatsCorrectly() {
        let time = CMTime(seconds: 3725, preferredTimescale: 600) // 62:05 (hours are converted to minutes)
        #expect(time.shortFormattedString == "62:05")
    }

    @Test func shortFormattedString_withInvalidTime_returnsDash() {
        let time = CMTime.invalid
        #expect(time.shortFormattedString == "-:--")
    }

    @Test func shortFormattedString_withIndefiniteTime_returnsDash() {
        let time = CMTime.indefinite
        #expect(time.shortFormattedString == "-:--")
    }
}
