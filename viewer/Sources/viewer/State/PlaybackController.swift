import AVFoundation
import Observation

struct VideoPlaybackState: Sendable {
    var currentTime: CMTime = .zero
    var duration: CMTime = .zero
    var isPlaying: Bool = false

    var progress: Double {
        guard duration.seconds > 0 else { return 0 }
        return currentTime.seconds / duration.seconds
    }
}

@Observable
@MainActor
final class PlaybackController {
    private(set) var state: PlaybackState = .stopped
    private(set) var mainVideoState = VideoPlaybackState()
    private(set) var overlayVideoState = VideoPlaybackState()

    private(set) var currentTime: CMTime {
        get { mainVideoState.currentTime }
        set { mainVideoState.currentTime = newValue }
    }

    private(set) var duration: CMTime {
        get { mainVideoState.duration }
        set { mainVideoState.duration = newValue }
    }

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

    var isPlaying: Bool { isMainPlaying || isOverlayPlaying }
    var isMainPlaying: Bool { mainVideoState.isPlaying }
    var isOverlayPlaying: Bool { overlayVideoState.isPlaying }
    var isReady: Bool { state == .ready || state == .playing || state == .paused }

    private var playerEntries: [Int: PlayerEntry] = [:]
    private var mainTimeObserver: Any?
    private var mainTimeObserverPlayer: AVPlayer?
    private var overlayTimeObserver: Any?
    private var overlayTimeObserverPlayer: AVPlayer?
    private var loopObservers: [NSObjectProtocol] = []
    private var overlayEndObserver: NSObjectProtocol?

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
        setupMainTimeObserver()
        setupOverlayTimeObserver()
        setupLoopObservers()
    }

    func unregister(for windowIndex: Int) {
        guard let entry = playerEntries[windowIndex] else { return }

        // 削除されるプレイヤーがタイムオブザーバーの対象なら先にオブザーバーを解除
        let isObservedMainPlayer = mainTimeObserverPlayer === entry.mainPlayer
        if isObservedMainPlayer {
            removeMainTimeObserver()
        }
        let isObservedOverlayPlayer = {
            guard let overlayPlayer = entry.overlayPlayer,
                  let observerPlayer = overlayTimeObserverPlayer else {
                return false
            }
            return observerPlayer === overlayPlayer
        }()
        if isObservedOverlayPlayer {
            removeOverlayTimeObserver()
        }

        entry.mainAccessedURL?.stopAccessingSecurityScopedResource()
        entry.overlayAccessedURL?.stopAccessingSecurityScopedResource()
        playerEntries.removeValue(forKey: windowIndex)

        updateState()

        // 他のプレイヤーが残っていれば新しいオブザーバーを設定
        if !playerEntries.isEmpty {
            if isObservedMainPlayer {
                setupMainTimeObserver()
                setupLoopObservers()
            }
            if isObservedOverlayPlayer {
                setupOverlayTimeObserver()
            }
        }
    }

    func play() {
        guard isReady else { return }
        playMain()
        playOverlay()
    }

    func pause() {
        pauseMain()
        pauseOverlay()
    }

    func togglePlayPause() {
        if isPlaying {
            pause()
        } else {
            play()
        }
    }

    func playMain() {
        guard isReady else { return }
        mainPlayers.forEach { $0.play() }
        mainVideoState.isPlaying = !mainPlayers.isEmpty
        updateAggregatePlaybackState()
    }

    func pauseMain() {
        mainPlayers.forEach { $0.pause() }
        mainVideoState.isPlaying = false
        updateAggregatePlaybackState()
    }

    func toggleMainPlayPause() {
        if isMainPlaying {
            pauseMain()
        } else {
            playMain()
        }
    }

    func playOverlay() {
        guard isReady, !overlayPlayers.isEmpty else {
            overlayVideoState.isPlaying = false
            updateAggregatePlaybackState()
            return
        }
        overlayPlayers.forEach { $0.play() }
        overlayVideoState.isPlaying = true
        updateAggregatePlaybackState()
    }

    func pauseOverlay() {
        overlayPlayers.forEach { $0.pause() }
        overlayVideoState.isPlaying = false
        updateAggregatePlaybackState()
    }

    func toggleOverlayPlayPause() {
        if isOverlayPlaying {
            pauseOverlay()
        } else {
            playOverlay()
        }
    }

    func seek(to time: CMTime) {
        allPlayers.forEach { player in
            player.seek(to: time, toleranceBefore: .zero, toleranceAfter: .zero)
        }
        currentTime = time
        if !overlayPlayers.isEmpty {
            overlayVideoState.currentTime = clampedTime(time, to: overlayVideoState.duration)
        }
    }

    func seekMain(to time: CMTime) {
        let targetTime = clampedTime(time, to: mainVideoState.duration)
        mainPlayers.forEach { player in
            player.seek(to: targetTime, toleranceBefore: .zero, toleranceAfter: .zero)
        }
        mainVideoState.currentTime = targetTime
    }

    func seekOverlay(to time: CMTime) {
        guard !overlayPlayers.isEmpty else { return }
        let targetTime = clampedTime(time, to: overlayVideoState.duration)
        overlayPlayers.forEach { player in
            player.seek(to: targetTime, toleranceBefore: .zero, toleranceAfter: .zero)
        }
        overlayVideoState.currentTime = targetTime
    }

    func syncOverlayToMain() {
        guard !overlayPlayers.isEmpty else { return }
        let targetTime = clampedTime(mainVideoState.currentTime, to: overlayVideoState.duration)
        overlayPlayers.forEach { player in
            player.seek(to: targetTime, toleranceBefore: .zero, toleranceAfter: .zero)
        }
        overlayVideoState.currentTime = targetTime
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

    private var mainPlayers: [AVPlayer] {
        playerEntries.values.map(\.mainPlayer)
    }

    private var overlayPlayers: [AVPlayer] {
        playerEntries.values.compactMap(\.overlayPlayer)
    }

    private var allPlayers: [AVPlayer] {
        mainPlayers + overlayPlayers
    }

    private func updateState() {
        if playerEntries.isEmpty {
            state = .stopped
            mainVideoState = VideoPlaybackState()
            overlayVideoState = VideoPlaybackState()
            removeMainTimeObserver()
            removeOverlayTimeObserver()
            removeLoopObservers()
        } else {
            let maxDuration = playerEntries.values.compactMap { entry -> CMTime? in
                entry.mainPlayer.currentItem?.duration
            }.max() ?? .zero

            if maxDuration.isValid && !maxDuration.isIndefinite {
                mainVideoState.duration = maxDuration
            }

            let overlayDurations = playerEntries.values.compactMap { entry -> CMTime? in
                entry.overlayPlayer?.currentItem?.duration
            }
            if let maxOverlayDuration = overlayDurations.max(), maxOverlayDuration.isValid && !maxOverlayDuration.isIndefinite {
                overlayVideoState.duration = maxOverlayDuration
            } else if overlayDurations.isEmpty {
                overlayVideoState = VideoPlaybackState()
            }

            if state == .stopped {
                state = .ready
            }
        }
        updateAggregatePlaybackState()
    }

    private func setupMainTimeObserver() {
        guard let firstEntry = playerEntries.values.first else { return }

        if let timeObserver = mainTimeObserver, let observerPlayer = mainTimeObserverPlayer {
            if observerPlayer === firstEntry.mainPlayer {
                return
            }
            observerPlayer.removeTimeObserver(timeObserver)
            mainTimeObserver = nil
            mainTimeObserverPlayer = nil
        }

        let interval = CMTime(seconds: 0.1, preferredTimescale: 600)
        let mainPlayer = firstEntry.mainPlayer
        let observer = mainPlayer.addPeriodicTimeObserver(
            forInterval: interval,
            queue: .main
        ) { [weak self] time in
            MainActor.assumeIsolated {
                self?.mainVideoState.currentTime = time
                // Update duration when it becomes available (async loading)
                if let duration = mainPlayer.currentItem?.duration,
                   duration.isValid, !duration.isIndefinite,
                   self?.mainVideoState.duration != duration {
                    self?.mainVideoState.duration = duration
                }
            }
        }
        mainTimeObserver = observer
        mainTimeObserverPlayer = firstEntry.mainPlayer
    }

    private func setupOverlayTimeObserver() {
        guard let overlayEntry = playerEntries.values.first(where: { $0.overlayPlayer != nil }),
              let overlayPlayer = overlayEntry.overlayPlayer else {
            removeOverlayTimeObserver()
            overlayVideoState.currentTime = .zero
            overlayVideoState.isPlaying = false
            return
        }

        if overlayTimeObserver != nil, let observerPlayer = overlayTimeObserverPlayer {
            if observerPlayer === overlayPlayer {
                return
            }
            removeOverlayTimeObserver()
        }

        let interval = CMTime(seconds: 0.1, preferredTimescale: 600)
        let observer = overlayPlayer.addPeriodicTimeObserver(
            forInterval: interval,
            queue: .main
        ) { [weak self] time in
            MainActor.assumeIsolated {
                self?.overlayVideoState.currentTime = time
                // Update duration when it becomes available (async loading)
                if let duration = overlayPlayer.currentItem?.duration,
                   duration.isValid, !duration.isIndefinite,
                   self?.overlayVideoState.duration != duration {
                    self?.overlayVideoState.duration = duration
                }
            }
        }
        overlayTimeObserver = observer
        overlayTimeObserverPlayer = overlayPlayer
        setupOverlayEndObserver(for: overlayPlayer)
    }

    private func setupLoopObservers() {
        removeLoopObservers()

        for entry in playerEntries.values {
            let observer = NotificationCenter.default.addObserver(
                forName: .AVPlayerItemDidPlayToEndTime,
                object: entry.mainPlayer.currentItem,
                queue: .main
            ) { [weak self] _ in
                MainActor.assumeIsolated {
                    self?.handleMainLoopRestart()
                }
            }
            loopObservers.append(observer)
        }
    }

    private func handleMainLoopRestart() {
        seekMain(to: .zero)
        if isMainPlaying {
            playMain()
        }
    }

    private func updateMuteState() {
        allPlayers.forEach { $0.isMuted = isMuted }
    }

    private func updateVolume() {
        allPlayers.forEach { $0.volume = volume }
    }

    private func removeLoopObservers() {
        loopObservers.forEach { NotificationCenter.default.removeObserver($0) }
        loopObservers.removeAll()
    }

    private func setupOverlayEndObserver(for player: AVPlayer) {
        if let overlayEndObserver {
            NotificationCenter.default.removeObserver(overlayEndObserver)
            self.overlayEndObserver = nil
        }

        overlayEndObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: player.currentItem,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.handleOverlayLoopRestart()
            }
        }
    }

    private func handleOverlayLoopRestart() {
        guard !overlayPlayers.isEmpty else { return }
        seekOverlay(to: .zero)
        if isOverlayPlaying {
            playOverlay()
        }
    }

    private func removeMainTimeObserver() {
        guard let observer = mainTimeObserver, let player = mainTimeObserverPlayer else { return }
        player.removeTimeObserver(observer)
        mainTimeObserver = nil
        mainTimeObserverPlayer = nil
    }

    private func removeOverlayTimeObserver() {
        if let overlayEndObserver {
            NotificationCenter.default.removeObserver(overlayEndObserver)
            self.overlayEndObserver = nil
        }
        guard let observer = overlayTimeObserver, let player = overlayTimeObserverPlayer else { return }
        player.removeTimeObserver(observer)
        overlayTimeObserver = nil
        overlayTimeObserverPlayer = nil
    }

    private func clampedTime(_ time: CMTime, to duration: CMTime) -> CMTime {
        let nonNegative = CMTimeMaximum(time, .zero)
        guard duration.isValid, !duration.isIndefinite else {
            return nonNegative
        }
        return CMTimeMinimum(nonNegative, duration)
    }

    private func updateAggregatePlaybackState() {
        guard !playerEntries.isEmpty else { return }
        if isMainPlaying || isOverlayPlaying {
            state = .playing
        } else if state == .playing {
            state = .paused
        }
    }

}
