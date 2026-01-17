import AVFoundation
import Observation

@Observable
@MainActor
final class PlaybackController {
    private(set) var state: PlaybackState = .stopped
    private(set) var currentTime: CMTime = .zero
    private(set) var duration: CMTime = .zero

    var isMuted: Bool = false {
        didSet {
            updateMuteState()
        }
    }

    var volume: Float = 1.0 {
        didSet {
            updateVolume()
        }
    }

    var isPlaying: Bool { state == .playing }
    var isReady: Bool { state == .ready || state == .playing || state == .paused }

    private var playerEntries: [Int: PlayerEntry] = [:]
    private var timeObserver: Any?
    private nonisolated(unsafe) var loopObservers: [NSObjectProtocol] = []

    struct PlayerEntry {
        let mainPlayer: AVPlayer
        let overlayPlayer: AVPlayer?
        var mainAccessedURL: URL?
        var overlayAccessedURL: URL?
    }

    func register(
        mainPlayer: AVPlayer,
        overlayPlayer: AVPlayer?,
        for windowIndex: Int,
        mainURL: URL? = nil,
        overlayURL: URL? = nil
    ) {
        playerEntries[windowIndex] = PlayerEntry(
            mainPlayer: mainPlayer,
            overlayPlayer: overlayPlayer,
            mainAccessedURL: mainURL,
            overlayAccessedURL: overlayURL
        )
        updateState()
        setupTimeObserver()
        setupLoopObservers()
    }

    func unregister(for windowIndex: Int) {
        if let entry = playerEntries[windowIndex] {
            entry.mainAccessedURL?.stopAccessingSecurityScopedResource()
            entry.overlayAccessedURL?.stopAccessingSecurityScopedResource()
        }
        playerEntries.removeValue(forKey: windowIndex)
        updateState()
    }

    func play() {
        guard isReady else { return }
        allPlayers.forEach { $0.play() }
        state = .playing
    }

    func pause() {
        allPlayers.forEach { $0.pause() }
        if state == .playing {
            state = .paused
        }
    }

    func togglePlayPause() {
        if isPlaying {
            pause()
        } else {
            play()
        }
    }

    func seek(to time: CMTime) {
        allPlayers.forEach { player in
            player.seek(to: time, toleranceBefore: .zero, toleranceAfter: .zero)
        }
        currentTime = time
    }

    func skipForward(seconds: Double = 10) {
        let newTime = CMTimeAdd(currentTime, CMTime(seconds: seconds, preferredTimescale: 600))
        let clampedTime = CMTimeMinimum(newTime, duration)
        seek(to: clampedTime)
    }

    func skipBackward(seconds: Double = 10) {
        let newTime = CMTimeSubtract(currentTime, CMTime(seconds: seconds, preferredTimescale: 600))
        let clampedTime = CMTimeMaximum(newTime, .zero)
        seek(to: clampedTime)
    }

    func goToBeginning() {
        seek(to: .zero)
    }

    private var allPlayers: [AVPlayer] {
        playerEntries.values.flatMap { entry -> [AVPlayer] in
            var players = [entry.mainPlayer]
            if let overlay = entry.overlayPlayer {
                players.append(overlay)
            }
            return players
        }
    }

    private func updateState() {
        if playerEntries.isEmpty {
            state = .stopped
            duration = .zero
        } else {
            let maxDuration = playerEntries.values.compactMap { entry -> CMTime? in
                entry.mainPlayer.currentItem?.duration
            }.max() ?? .zero

            if maxDuration.isValid && !maxDuration.isIndefinite {
                duration = maxDuration
            }

            if state == .stopped {
                state = .ready
            }
        }
    }

    private func setupTimeObserver() {
        guard timeObserver == nil, let firstEntry = playerEntries.values.first else { return }

        let interval = CMTime(seconds: 0.1, preferredTimescale: 600)
        timeObserver = firstEntry.mainPlayer.addPeriodicTimeObserver(
            forInterval: interval,
            queue: .main
        ) { [weak self] time in
            Task { @MainActor in
                self?.currentTime = time
            }
        }
    }

    private func setupLoopObservers() {
        loopObservers.forEach { NotificationCenter.default.removeObserver($0) }
        loopObservers.removeAll()

        for entry in playerEntries.values {
            let observer = NotificationCenter.default.addObserver(
                forName: .AVPlayerItemDidPlayToEndTime,
                object: entry.mainPlayer.currentItem,
                queue: .main
            ) { [weak self] _ in
                Task { @MainActor in
                    self?.handleLoopRestart()
                }
            }
            loopObservers.append(observer)
        }
    }

    private func handleLoopRestart() {
        goToBeginning()
        if isPlaying {
            play()
        }
    }

    private func updateMuteState() {
        allPlayers.forEach { $0.isMuted = isMuted }
    }

    private func updateVolume() {
        allPlayers.forEach { $0.volume = volume }
    }

    deinit {
        loopObservers.forEach { NotificationCenter.default.removeObserver($0) }
    }
}
