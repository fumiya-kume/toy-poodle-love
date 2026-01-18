import AppKit
import SwiftUI
import Observation

/// Manages the overlay control panel lifecycle and window focus.
@Observable
@MainActor
final class OpacityPanelController {
    // MARK: - Public Properties

    private(set) var isVisible: Bool = false
    private(set) var focusedWindowId: Int?

    // MARK: - Private Properties

    private var panel: NSPanel?
    private weak var appState: AppState?
    private var panelDelegate: PanelDelegate?  // Strong reference to delegate

    // UserDefaults keys for panel position/size persistence
    private let panelFrameKey = "opacityPanelFrame"

    // MARK: - Initialization

    func initialize(appState: AppState) {
        self.appState = appState
    }

    // MARK: - Panel Visibility

    func toggle() {
        if isVisible {
            hide()
        } else {
            show()
        }
    }

    func show() {
        guard !isVisible else {
            return
        }

        if panel == nil {
            createPanel()
        }

        guard let panel = panel else {
            return
        }

        // Restore saved position/size or center on screen
        if let frameData = UserDefaults.standard.data(forKey: panelFrameKey),
           let frameDict = try? JSONDecoder().decode([String: CGFloat].self, from: frameData) {
            let frame = NSRect(
                x: frameDict["x"] ?? 0,
                y: frameDict["y"] ?? 0,
                width: frameDict["width"] ?? 280,
                height: frameDict["height"] ?? 80
            )
            panel.setFrame(frame, display: false)
        } else {
            panel.center()
        }

        panel.makeKeyAndOrderFront(nil)
        isVisible = true
    }

    func hide() {
        guard isVisible, let panel = panel else { return }

        // Save current position/size
        savePanelFrame()

        panel.orderOut(nil)
        isVisible = false
    }

    // MARK: - Window Focus Tracking

    func setFocusedWindow(_ windowId: Int) {
        focusedWindowId = windowId
    }

    func clearFocusedWindow(_ windowId: Int) {
        if focusedWindowId == windowId {
            focusedWindowId = nil

            // Auto-close panel when no windows are focused
            if isVisible {
                hide()
            }
        }
    }

    // MARK: - Overlay Control

    /// Binding for the overlay visibility control.
    var opacityBinding: Binding<Double> {
        Binding(
            get: { [weak self] in
                guard let self = self,
                      let windowId = focusedWindowId,
                      let config = appState?.configuration(for: windowId) else {
                    return 1.0
                }
                return config.overlayOpacity
            },
            set: { [weak self] newValue in
                guard let self = self,
                      let windowId = focusedWindowId else { return }
                let normalized = newValue > 0.5 ? 1.0 : 0.0
                appState?.setOverlayOpacity(at: windowId, opacity: normalized)
            }
        )
    }

    /// Current overlay opacity (read-only).
    var currentOpacity: Double {
        guard let windowId = focusedWindowId,
              let config = appState?.configuration(for: windowId) else {
            return 1.0
        }
        return config.overlayOpacity
    }

    /// Toggle overlay visibility (for keyboard shortcut)
    func toggleOverlayVisibility() {
        guard let windowId = focusedWindowId else { return }
        let newValue = currentOpacity > 0.5 ? 0.0 : 1.0
        withAnimation(.easeInOut(duration: 0.2)) {
            appState?.setOverlayOpacity(at: windowId, opacity: newValue)
        }
    }

    // MARK: - Private Methods

    private func createPanel() {
        guard let appState = appState else {
            return
        }

        let panelView = OpacityPanelView()
            .environment(appState)

        let hostingController = NSHostingController(rootView: panelView)

        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 280, height: 80),
            styleMask: [.titled, .closable, .resizable, .utilityWindow, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        panel.title = "Overlay Control"
        panel.contentViewController = hostingController
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.isFloatingPanel = true
        panel.isMovableByWindowBackground = true
        panel.hidesOnDeactivate = false
        panel.becomesKeyOnlyIfNeeded = true

        // Set minimum size based on content
        panel.contentMinSize = NSSize(width: 200, height: 60)

        // Handle close button (hide instead of destroy)
        let delegate = PanelDelegate(controller: self)
        self.panelDelegate = delegate
        panel.delegate = delegate

        self.panel = panel
    }

    private func savePanelFrame() {
        guard let panel = panel else { return }
        let frame = panel.frame
        let frameDict: [String: CGFloat] = [
            "x": frame.origin.x,
            "y": frame.origin.y,
            "width": frame.size.width,
            "height": frame.size.height
        ]
        if let data = try? JSONEncoder().encode(frameDict) {
            UserDefaults.standard.set(data, forKey: panelFrameKey)
        }
    }
}

// MARK: - Panel Delegate

/// NSPanel delegate to intercept close button
private class PanelDelegate: NSObject, NSWindowDelegate {
    weak var controller: OpacityPanelController?

    init(controller: OpacityPanelController) {
        self.controller = controller
    }

    func windowShouldClose(_ sender: NSWindow) -> Bool {
        // Hide instead of close
        Task { @MainActor in
            controller?.hide()
        }
        return false
    }

    func windowWillClose(_ notification: Notification) {
        // ESC key triggers this - mark as not visible
        Task { @MainActor in
            controller?.markAsHidden()
        }
    }
}

// MARK: - Internal Methods (for delegate access)

extension OpacityPanelController {
    /// Called by delegate when panel is closed
    fileprivate func markAsHidden() {
        isVisible = false
    }
}
