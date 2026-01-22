import Foundation
import Testing
@testable import VideoOverlayViewer

@MainActor
struct OpacityPanelControllerTests {
    // MARK: - Initial State Tests

    @Test func initialState_isNotVisible() {
        let controller = OpacityPanelController()
        #expect(controller.isVisible == false)
    }

    @Test func initialState_focusedWindowId_isNil() {
        let controller = OpacityPanelController()
        #expect(controller.focusedWindowId == nil)
    }

    // MARK: - Window Focus Tests

    @Test func setFocusedWindow_setsFocusedWindowId() {
        let controller = OpacityPanelController()

        controller.setFocusedWindow(123)

        #expect(controller.focusedWindowId == 123)
    }

    @Test func setFocusedWindow_canChangeToNewWindow() {
        let controller = OpacityPanelController()
        controller.setFocusedWindow(100)

        controller.setFocusedWindow(200)

        #expect(controller.focusedWindowId == 200)
    }

    @Test func clearFocusedWindow_clearsId_whenMatchingWindow() {
        let controller = OpacityPanelController()
        controller.setFocusedWindow(123)

        controller.clearFocusedWindow(123)

        #expect(controller.focusedWindowId == nil)
    }

    @Test func clearFocusedWindow_doesNotClear_whenDifferentWindow() {
        let controller = OpacityPanelController()
        controller.setFocusedWindow(123)

        controller.clearFocusedWindow(456)

        #expect(controller.focusedWindowId == 123)
    }

    @Test func clearFocusedWindow_noOp_whenNoFocusedWindow() {
        let controller = OpacityPanelController()

        controller.clearFocusedWindow(123)

        #expect(controller.focusedWindowId == nil)
    }

    // MARK: - Current Opacity Tests

    @Test func currentOpacity_returns1_whenNoFocusedWindow() {
        let controller = OpacityPanelController()

        #expect(controller.currentOpacity == 1.0)
    }

    @Test func currentOpacity_returns1_whenNoAppStateInitialized() {
        let controller = OpacityPanelController()
        controller.setFocusedWindow(123)

        // No appState initialized, should return default
        #expect(controller.currentOpacity == 1.0)
    }

    // MARK: - Toggle Overlay Visibility Tests

    @Test func toggleOverlayVisibility_noOp_whenNoFocusedWindow() {
        let controller = OpacityPanelController()

        // Should not crash when no focused window
        controller.toggleOverlayVisibility()

        #expect(controller.focusedWindowId == nil)
    }

    // MARK: - Multiple Window Focus Tests

    @Test func multipleWindowFocus_tracksLatestWindow() {
        let controller = OpacityPanelController()

        controller.setFocusedWindow(1)
        #expect(controller.focusedWindowId == 1)

        controller.setFocusedWindow(2)
        #expect(controller.focusedWindowId == 2)

        controller.setFocusedWindow(3)
        #expect(controller.focusedWindowId == 3)
    }

    @Test func clearFocusedWindow_sequence() {
        let controller = OpacityPanelController()

        controller.setFocusedWindow(1)
        controller.clearFocusedWindow(1)
        #expect(controller.focusedWindowId == nil)

        controller.setFocusedWindow(2)
        controller.clearFocusedWindow(2)
        #expect(controller.focusedWindowId == nil)
    }

    // MARK: - Edge Case Tests

    @Test func setFocusedWindow_withZeroId() {
        let controller = OpacityPanelController()

        controller.setFocusedWindow(0)

        #expect(controller.focusedWindowId == 0)
    }

    @Test func setFocusedWindow_withNegativeId() {
        let controller = OpacityPanelController()

        controller.setFocusedWindow(-1)

        #expect(controller.focusedWindowId == -1)
    }

    @Test func setFocusedWindow_withLargeId() {
        let controller = OpacityPanelController()

        controller.setFocusedWindow(Int.max)

        #expect(controller.focusedWindowId == Int.max)
    }

    @Test func clearFocusedWindow_withZeroId() {
        let controller = OpacityPanelController()
        controller.setFocusedWindow(0)

        controller.clearFocusedWindow(0)

        #expect(controller.focusedWindowId == nil)
    }
}
