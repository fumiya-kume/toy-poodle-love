import XCTest
@testable import VideoOverlayViewer

final class VideoConfigurationTests: XCTestCase {
    func testDefaultConfigurations() {
        let configs = VideoConfiguration.defaultConfigurations()
        XCTAssertEqual(configs.count, 3)
        XCTAssertEqual(configs[0].windowIndex, 0)
        XCTAssertEqual(configs[1].windowIndex, 1)
        XCTAssertEqual(configs[2].windowIndex, 2)
    }

    func testDefaultOpacity() {
        let config = VideoConfiguration(windowIndex: 0)
        XCTAssertEqual(config.overlayOpacity, 0.5)
    }

    func testNilURLsWithoutBookmarks() {
        let config = VideoConfiguration(windowIndex: 0)
        XCTAssertNil(config.mainVideoURL)
        XCTAssertNil(config.overlayVideoURL)
    }
}

final class AppSettingsTests: XCTestCase {
    func testDefaultValues() {
        let settings = AppSettings.default
        XCTAssertFalse(settings.autoPlayOnLaunch)
        XCTAssertTrue(settings.showControlsOnHover)
        XCTAssertEqual(settings.controlHideDelay, 3.0)
        XCTAssertTrue(settings.rememberWindowPositions)
    }
}

final class WindowIdentifierTests: XCTestCase {
    func testAllCases() {
        XCTAssertEqual(WindowIdentifier.allCases.count, 3)
    }

    func testIndex() {
        XCTAssertEqual(WindowIdentifier.video1.index, 0)
        XCTAssertEqual(WindowIdentifier.video2.index, 1)
        XCTAssertEqual(WindowIdentifier.video3.index, 2)
    }

    func testFromIndex() {
        XCTAssertEqual(WindowIdentifier.from(index: 0), .video1)
        XCTAssertEqual(WindowIdentifier.from(index: 1), .video2)
        XCTAssertEqual(WindowIdentifier.from(index: 2), .video3)
        XCTAssertNil(WindowIdentifier.from(index: 3))
    }

    func testDisplayName() {
        XCTAssertEqual(WindowIdentifier.video1.displayName, "Video Window 1")
        XCTAssertEqual(WindowIdentifier.video2.displayName, "Video Window 2")
        XCTAssertEqual(WindowIdentifier.video3.displayName, "Video Window 3")
    }
}
