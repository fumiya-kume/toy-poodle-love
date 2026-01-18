import Foundation
import Observation

@Observable
@MainActor
final class AppState {
    var videoConfigurations: [VideoConfiguration]
    var appSettings: AppSettings
    var playbackController: PlaybackController
    var opacityPanelController: OpacityPanelController

    // Scenario Writer 関連
    var scenarioWriterState: ScenarioWriterState
    var subtitleState: SubtitleState
    var ttsController: TTSController

    /// 開いている Video Player ウィンドウの数
    var openVideoPlayerCount: Int = 0

    /// Video Player が1つ以上開いているか
    var hasVideoPlayers: Bool { openVideoPlayerCount > 0 }

    private let configurationsKey = "videoConfigurations"
    private let settingsKey = "appSettings"

    init() {
        var needsOverlayOpacityNormalization = false

        if let data = UserDefaults.standard.data(forKey: configurationsKey),
           let configs = try? JSONDecoder().decode([VideoConfiguration].self, from: data) {
            let normalized = configs.map { config in
                var updated = config
                if updated.overlayOpacity != 0.0 && updated.overlayOpacity != 1.0 {
                    updated.overlayOpacity = 1.0
                    needsOverlayOpacityNormalization = true
                }
                return updated
            }
            self.videoConfigurations = normalized
        } else {
            self.videoConfigurations = VideoConfiguration.defaultConfigurations()
        }

        if let data = UserDefaults.standard.data(forKey: settingsKey),
           let settings = try? JSONDecoder().decode(AppSettings.self, from: data) {
            self.appSettings = settings
        } else {
            self.appSettings = AppSettings.default
        }

        self.playbackController = PlaybackController()
        self.opacityPanelController = OpacityPanelController()

        // Scenario Writer 関連の初期化
        self.scenarioWriterState = ScenarioWriterState()
        self.subtitleState = SubtitleState()
        self.ttsController = TTSController()

        // Initialize opacity panel controller with self reference
        self.opacityPanelController.initialize(appState: self)

        // TTS コントローラーに字幕状態を設定
        self.ttsController.setSubtitleState(self.subtitleState)

        if needsOverlayOpacityNormalization {
            save()
        }
    }

    func save() {
        if let data = try? JSONEncoder().encode(videoConfigurations) {
            UserDefaults.standard.set(data, forKey: configurationsKey)
        }
        if let data = try? JSONEncoder().encode(appSettings) {
            UserDefaults.standard.set(data, forKey: settingsKey)
        }
    }

    func configuration(for index: Int) -> VideoConfiguration? {
        videoConfigurations.first { $0.windowIndex == index }
    }

    func configurationBinding(for index: Int) -> VideoConfiguration {
        configuration(for: index) ?? VideoConfiguration(windowIndex: index)
    }

    /// 指定インデックスの設定を確保（存在しなければ作成）
    func ensureConfiguration(for index: Int) {
        if configuration(for: index) == nil {
            videoConfigurations.append(VideoConfiguration(windowIndex: index))
            save()
        }
    }

    func updateConfiguration(at index: Int, _ update: (inout VideoConfiguration) -> Void) {
        // 設定が存在しない場合は作成
        ensureConfiguration(for: index)
        guard let configIndex = videoConfigurations.firstIndex(where: { $0.windowIndex == index }) else { return }
        update(&videoConfigurations[configIndex])
        save()
    }

    func setMainVideo(at index: Int, url: URL) {
        guard let bookmark = VideoConfiguration.createBookmark(for: url) else { return }
        updateConfiguration(at: index) { config in
            config.mainVideoBookmark = bookmark
        }
    }

    func setOverlayVideo(at index: Int, url: URL) {
        guard let bookmark = VideoConfiguration.createBookmark(for: url) else { return }
        updateConfiguration(at: index) { config in
            config.overlayVideoBookmark = bookmark
        }
    }

    func clearMainVideo(at index: Int) {
        updateConfiguration(at: index) { config in
            config.mainVideoBookmark = nil
        }
    }

    func clearOverlayVideo(at index: Int) {
        updateConfiguration(at: index) { config in
            config.overlayVideoBookmark = nil
        }
    }

    func setOverlayOpacity(at index: Int, opacity: Double) {
        updateConfiguration(at: index) { config in
            config.overlayOpacity = opacity
        }
    }

    func resetToDefaults() {
        videoConfigurations = VideoConfiguration.defaultConfigurations()
        appSettings = AppSettings.default
        save()
    }
}
