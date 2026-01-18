import SwiftUI
import AVKit
import AVFoundation
import UniformTypeIdentifiers

struct VideoPlayerWindow: View {
    @Environment(AppState.self) private var appState
    @State private var showControls = true
    @State private var controlsTimer: Timer?
    @State private var controlsTimerTarget = ControlsTimerTarget()
    @State private var mainSlot = VideoSlot()
    @State private var overlaySlot = VideoSlot()
    @State private var windowId = UUID()

    private var windowIndex: Int { windowId.hashValue }

    // Load persisted opacity for this window.
    private var overlayOpacity: Double {
        appState.configuration(for: windowIndex)?.overlayOpacity ?? 1.0
    }

    // Binding to persist opacity changes.
    private var overlayOpacityBinding: Binding<Double> {
        Binding(
            get: { appState.configuration(for: windowIndex)?.overlayOpacity ?? 1.0 },
            set: { newValue in
                appState.setOverlayOpacity(at: windowIndex, opacity: newValue)
            }
        )
    }

    var body: some View {
        ZStack {
            Color.black

            if let player = mainSlot.player {
                VideoPlayerView(player: player, style: .main)
            } else {
                VStack(spacing: 16) {
                    Image(systemName: "video.badge.plus")
                        .font(.system(size: 48))
                        .foregroundStyle(.secondary)
                    Text("Drop video file here or use the buttons below")
                        .foregroundStyle(.secondary)

                    HStack(spacing: 12) {
                        Button("Select Main Video") {
                            selectVideo(.main)
                        }
                        Button("Select Overlay Video") {
                            selectVideo(.overlay)
                        }
                    }
                }
            }

            if let player = overlaySlot.player {
                VideoPlayerView(player: player, style: .overlay)
                    .opacity(overlayOpacity)
                    .animation(.easeInOut(duration: 0.2), value: overlayOpacity)
                    .allowsHitTesting(false)
            }

            // 字幕オーバーレイ
            SubtitleOverlayView()

            if showControls || !appState.playbackController.isPlaying {
                VideoControlsOverlay(
                    opacity: overlayOpacityBinding,
                    playbackController: appState.playbackController,
                    hasOverlay: overlaySlot.player != nil
                )
                .transition(.opacity.animation(.easeInOut(duration: 0.2)))
            }
        }
        .onHover { hovering in
            if hovering {
                showControls = true
                resetControlsTimer()
            } else if appState.playbackController.isPlaying {
                showControls = false
                controlsTimer?.invalidate()
            }
        }
        .onTapGesture {
            // Update focus when the window is clicked.
            appState.opacityPanelController.setFocusedWindow(windowIndex)
            appState.playbackController.togglePlayPause()
        }
        .onDrop(of: [.fileURL], isTargeted: nil) { providers in
            handleDrop(providers: providers)
        }
        .onAppear {
            // Ensure configuration exists for this window.
            appState.ensureConfiguration(for: windowIndex)
            // Notify the opacity panel which window is active.
            appState.opacityPanelController.setFocusedWindow(windowIndex)
            // Track open window count
            appState.openVideoPlayerCount += 1
        }
        .onDisappear {
            unloadVideos()
            controlsTimer?.invalidate()
            controlsTimer = nil
            // Clear focus when the window closes.
            appState.opacityPanelController.clearFocusedWindow(windowIndex)
            // Track open window count
            appState.openVideoPlayerCount -= 1
        }
        .focusable()
        .onKeyPress(.space) {
            appState.playbackController.togglePlayPause()
            return .handled
        }
        .onKeyPress(characters: CharacterSet(charactersIn: "1")) { _ in
            appState.playbackController.toggleMainPlayPause()
            return .handled
        }
        .onKeyPress(characters: CharacterSet(charactersIn: "2")) { _ in
            appState.playbackController.toggleOverlayPlayPause()
            return .handled
        }
        .onKeyPress(.leftArrow) {
            appState.playbackController.skipBackward()
            return .handled
        }
        .onKeyPress(.rightArrow) {
            appState.playbackController.skipForward()
            return .handled
        }
        .onKeyPress(characters: CharacterSet(charactersIn: "mM")) { _ in
            appState.playbackController.isMuted.toggle()
            return .handled
        }
        .toolbar {
            ToolbarItemGroup {
                Button(action: { selectVideo(.main) }) {
                    Label("Main Video", systemImage: "film")
                }
                .help("Select main video file")

                Button(action: { selectVideo(.overlay) }) {
                    Label("Overlay", systemImage: "square.stack")
                }
                .help("Select overlay video file")
            }
        }
    }

    private func selectVideo(_ kind: VideoKind) {
        let panel = makeOpenPanel(message: kind.openPanelMessage)
        if panel.runModal() == .OK, let url = panel.url {
            loadVideo(url: url, kind: kind)
        }
    }

    private func makeOpenPanel(message: String) -> NSOpenPanel {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = Self.allowedContentTypes
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.message = message
        return panel
    }

    private func loadVideo(url: URL, kind: VideoKind) {
        switch kind {
        case .main:
            mainSlot.load(url: url)
        case .overlay:
            overlaySlot.load(url: url)
        }
        registerPlayers()
    }

    private func registerPlayers() {
        guard let mainPlayer = mainSlot.player else { return }
        appState.playbackController.register(
            mainPlayer: mainPlayer,
            overlayPlayer: overlaySlot.player,
            for: windowIndex,
            mainURL: mainSlot.accessedURL,
            overlayURL: overlaySlot.accessedURL
        )
    }

    private func unloadVideos() {
        appState.playbackController.unregister(for: windowIndex)
        mainSlot.unload()
        overlaySlot.unload()
    }

    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first else { return false }

        provider.loadItem(forTypeIdentifier: "public.file-url", options: nil) { item, _ in
            guard let data = item as? Data,
                  let url = URL(dataRepresentation: data, relativeTo: nil) else { return }

            let videoExtensions = ["mp4", "mov", "m4v", "mpeg4"]
            guard videoExtensions.contains(url.pathExtension.lowercased()) else { return }

            DispatchQueue.main.async {
                if mainSlot.player == nil {
                    loadVideo(url: url, kind: .main)
                } else {
                    loadVideo(url: url, kind: .overlay)
                }
            }
        }
        return true
    }

    private func resetControlsTimer() {
        controlsTimer?.invalidate()
        controlsTimerTarget.isPlaying = { appState.playbackController.isPlaying }
        controlsTimerTarget.hideControls = { showControls = false }
        controlsTimer = Timer.scheduledTimer(
            timeInterval: appState.appSettings.controlHideDelay,
            target: controlsTimerTarget,
            selector: #selector(ControlsTimerTarget.handleTimer(_:)),
            userInfo: nil,
            repeats: false
        )
    }
}

@MainActor
private final class ControlsTimerTarget: NSObject {
    var isPlaying: (() -> Bool)?
    var hideControls: (() -> Void)?

    @objc func handleTimer(_ timer: Timer) {
        guard isPlaying?() == true else { return }
        hideControls?()
    }
}

private extension VideoPlayerWindow {
    static let allowedContentTypes: [UTType] = [.movie, .video, .mpeg4Movie, .quickTimeMovie]

    enum VideoKind {
        case main
        case overlay

        var openPanelMessage: String {
            switch self {
            case .main:
                return "Select main video"
            case .overlay:
                return "Select overlay video"
            }
        }
    }

    struct VideoSlot {
        var player: AVPlayer?
        var accessedURL: URL?

        mutating func load(url: URL) {
            accessedURL?.stopAccessingSecurityScopedResource()
            guard url.startAccessingSecurityScopedResource() else { return }
            accessedURL = url
            player = AVPlayer(url: url)
        }

        mutating func unload() {
            player?.pause()
            accessedURL?.stopAccessingSecurityScopedResource()
            player = nil
            accessedURL = nil
        }
    }
}

#Preview {
    VideoPlayerWindow()
        .environment(AppState())
        .frame(width: 800, height: 600)
}
