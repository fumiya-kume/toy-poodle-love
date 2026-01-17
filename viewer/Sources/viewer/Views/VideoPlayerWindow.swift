import SwiftUI
import AVKit
import AVFoundation

struct VideoPlayerWindow: View {
    @Environment(AppState.self) private var appState
    @State private var showControls = true
    @State private var controlsTimer: Timer?
    @State private var mainPlayer: AVPlayer?
    @State private var overlayPlayer: AVPlayer?
    @State private var mainAccessedURL: URL?
    @State private var overlayAccessedURL: URL?
    @State private var windowId = UUID()

    /// VideoConfigurationから透明度を取得（永続化対応）
    private var overlayOpacity: Double {
        appState.configuration(for: windowId.hashValue)?.overlayOpacity ?? 0.5
    }

    /// 透明度を変更するためのBinding
    private var overlayOpacityBinding: Binding<Double> {
        Binding(
            get: { appState.configuration(for: windowId.hashValue)?.overlayOpacity ?? 0.5 },
            set: { newValue in
                appState.setOverlayOpacity(at: windowId.hashValue, opacity: newValue)
            }
        )
    }

    var body: some View {
        ZStack {
            Color.black

            if let player = mainPlayer {
                MainVideoPlayerView(player: player)
            } else {
                VStack(spacing: 16) {
                    Image(systemName: "video.badge.plus")
                        .font(.system(size: 48))
                        .foregroundStyle(.secondary)
                    Text("Drop video file here or use the buttons below")
                        .foregroundStyle(.secondary)

                    HStack(spacing: 12) {
                        Button("Select Main Video") {
                            selectMainVideo()
                        }
                        Button("Select Overlay Video") {
                            selectOverlayVideo()
                        }
                    }
                }
            }

            if let player = overlayPlayer {
                OverlayVideoPlayerView(player: player)
                    .opacity(overlayOpacity)
                    .allowsHitTesting(false)
            }

            if showControls || !appState.playbackController.isPlaying {
                VideoControlsOverlay(
                    opacity: overlayOpacityBinding,
                    isPlaying: Binding(
                        get: { appState.playbackController.isPlaying },
                        set: { _ in }
                    ),
                    currentTime: Binding(
                        get: { appState.playbackController.currentTime },
                        set: { _ in }
                    ),
                    duration: Binding(
                        get: { appState.playbackController.duration },
                        set: { _ in }
                    ),
                    isMuted: Binding(
                        get: { appState.playbackController.isMuted },
                        set: { appState.playbackController.isMuted = $0 }
                    ),
                    onPlayPause: { appState.playbackController.togglePlayPause() },
                    onSeek: { appState.playbackController.seek(to: $0) },
                    onSkipBackward: { appState.playbackController.skipBackward() },
                    onSkipForward: { appState.playbackController.skipForward() }
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
            // ウィンドウクリック時にフォーカスを更新
            appState.opacityPanelController.setFocusedWindow(windowId.hashValue)
            appState.playbackController.togglePlayPause()
        }
        .onDrop(of: [.fileURL], isTargeted: nil) { providers in
            handleDrop(providers: providers)
        }
        .onAppear {
            // ウィンドウ用の設定を確保（存在しなければ作成）
            appState.ensureConfiguration(for: windowId.hashValue)
            // パネルにフォーカスを通知
            appState.opacityPanelController.setFocusedWindow(windowId.hashValue)
        }
        .onDisappear {
            unloadVideos()
            // パネルからフォーカスをクリア
            appState.opacityPanelController.clearFocusedWindow(windowId.hashValue)
        }
        .focusable()
        .onKeyPress(.space) {
            appState.playbackController.togglePlayPause()
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
                Button(action: selectMainVideo) {
                    Label("Main Video", systemImage: "film")
                }
                .help("Select main video file")

                Button(action: selectOverlayVideo) {
                    Label("Overlay", systemImage: "square.stack")
                }
                .help("Select overlay video file")
            }
        }
    }

    private func selectMainVideo() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.movie, .video, .mpeg4Movie, .quickTimeMovie]
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.message = "Select main video"

        if panel.runModal() == .OK, let url = panel.url {
            loadMainVideo(url: url)
        }
    }

    private func selectOverlayVideo() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.movie, .video, .mpeg4Movie, .quickTimeMovie]
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.message = "Select overlay video"

        if panel.runModal() == .OK, let url = panel.url {
            loadOverlayVideo(url: url)
        }
    }

    private func loadMainVideo(url: URL) {
        mainAccessedURL?.stopAccessingSecurityScopedResource()

        guard url.startAccessingSecurityScopedResource() else { return }
        mainAccessedURL = url
        mainPlayer = AVPlayer(url: url)

        registerPlayers()
    }

    private func loadOverlayVideo(url: URL) {
        overlayAccessedURL?.stopAccessingSecurityScopedResource()

        guard url.startAccessingSecurityScopedResource() else { return }
        overlayAccessedURL = url
        overlayPlayer = AVPlayer(url: url)

        registerPlayers()
    }

    private func registerPlayers() {
        if let main = mainPlayer {
            appState.playbackController.register(
                mainPlayer: main,
                overlayPlayer: overlayPlayer,
                for: windowId.hashValue,
                mainURL: mainAccessedURL,
                overlayURL: overlayAccessedURL
            )
        }
    }

    private func unloadVideos() {
        appState.playbackController.unregister(for: windowId.hashValue)

        mainPlayer?.pause()
        overlayPlayer?.pause()

        mainAccessedURL?.stopAccessingSecurityScopedResource()
        overlayAccessedURL?.stopAccessingSecurityScopedResource()

        mainPlayer = nil
        overlayPlayer = nil
        mainAccessedURL = nil
        overlayAccessedURL = nil
    }

    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first else { return false }

        provider.loadItem(forTypeIdentifier: "public.file-url", options: nil) { item, _ in
            guard let data = item as? Data,
                  let url = URL(dataRepresentation: data, relativeTo: nil) else { return }

            let videoExtensions = ["mp4", "mov", "m4v", "mpeg4"]
            guard videoExtensions.contains(url.pathExtension.lowercased()) else { return }

            DispatchQueue.main.async {
                if mainPlayer == nil {
                    loadMainVideo(url: url)
                } else {
                    loadOverlayVideo(url: url)
                }
            }
        }
        return true
    }

    private func resetControlsTimer() {
        controlsTimer?.invalidate()
        controlsTimer = Timer.scheduledTimer(withTimeInterval: appState.appSettings.controlHideDelay, repeats: false) { _ in
            if appState.playbackController.isPlaying {
                showControls = false
            }
        }
    }
}

#Preview {
    VideoPlayerWindow()
        .environment(AppState())
        .frame(width: 800, height: 600)
}
