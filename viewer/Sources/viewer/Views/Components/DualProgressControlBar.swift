import SwiftUI
import AVFoundation

struct DualProgressControlBar: View {
    let isPlaying: Bool
    let mainState: VideoPlaybackState
    let overlayState: VideoPlaybackState
    let hasOverlay: Bool
    @Binding var isMuted: Bool

    var onPlayPause: () -> Void
    var onMainPlayPause: () -> Void
    var onOverlayPlayPause: () -> Void
    var onSeekMain: (CMTime) -> Void
    var onSeekOverlay: (CMTime) -> Void
    var onSkipBackward: () -> Void
    var onSkipForward: () -> Void
    var onSyncOverlay: () -> Void

    private var showsOverlayBar: Bool {
        guard hasOverlay else { return false }
        return overlayState.duration.isValid
            && !overlayState.duration.isIndefinite
            && overlayState.duration.seconds > 0
    }

    var body: some View {
        VStack(spacing: 10) {
            HStack(spacing: 16) {
                Button(action: onPlayPause) {
                    Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 20))
                        .frame(width: 32, height: 32)
                }
                .buttonStyle(.plain)

                Button(action: onSkipBackward) {
                    Image(systemName: "gobackward.10")
                        .font(.system(size: 16))
                }
                .buttonStyle(.plain)

                Button(action: onSkipForward) {
                    Image(systemName: "goforward.10")
                        .font(.system(size: 16))
                }
                .buttonStyle(.plain)

                Spacer()

                if hasOverlay {
                    Button(action: onSyncOverlay) {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.system(size: 16))
                            .frame(width: 24)
                    }
                    .buttonStyle(.plain)
                }

                Button(action: { isMuted.toggle() }) {
                    Image(systemName: isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                        .font(.system(size: 16))
                        .frame(width: 24)
                }
                .buttonStyle(.plain)
            }

            VideoProgressBar(
                label: "Main",
                labelColor: .blue,
                currentTime: mainState.currentTime,
                duration: mainState.duration,
                onSeek: onSeekMain,
                isPlaying: mainState.isPlaying,
                onPlayPause: onMainPlayPause
            )

            if showsOverlayBar {
                VideoProgressBar(
                    label: "Overlay",
                    labelColor: .orange,
                    currentTime: overlayState.currentTime,
                    duration: overlayState.duration,
                    onSeek: onSeekOverlay,
                    isPlaying: overlayState.isPlaying,
                    onPlayPause: onOverlayPlayPause
                )
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }
}

#Preview {
    DualProgressControlBar(
        isPlaying: false,
        mainState: VideoPlaybackState(
            currentTime: CMTime(seconds: 83, preferredTimescale: 600),
            duration: CMTime(seconds: 300, preferredTimescale: 600)
        ),
        overlayState: VideoPlaybackState(
            currentTime: CMTime(seconds: 48, preferredTimescale: 600),
            duration: CMTime(seconds: 210, preferredTimescale: 600)
        ),
        hasOverlay: true,
        isMuted: .constant(false),
        onPlayPause: {},
        onMainPlayPause: {},
        onOverlayPlayPause: {},
        onSeekMain: { _ in },
        onSeekOverlay: { _ in },
        onSkipBackward: {},
        onSkipForward: {},
        onSyncOverlay: {}
    )
    .padding()
    .background(.ultraThinMaterial)
    .clipShape(RoundedRectangle(cornerRadius: 12))
    .frame(width: 480)
}
