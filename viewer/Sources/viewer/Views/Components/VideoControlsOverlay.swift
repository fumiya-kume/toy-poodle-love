import SwiftUI
import AVFoundation

struct VideoControlsOverlay: View {
    @Binding var opacity: Double
    @Binding var isPlaying: Bool
    @Binding var currentTime: CMTime
    @Binding var duration: CMTime
    @Binding var isMuted: Bool

    var onPlayPause: () -> Void
    var onSeek: (CMTime) -> Void
    var onSkipBackward: () -> Void
    var onSkipForward: () -> Void

    var body: some View {
        VStack {
            Spacer()

            VStack(spacing: 12) {
                PlaybackControlBar(
                    isPlaying: $isPlaying,
                    currentTime: $currentTime,
                    duration: $duration,
                    isMuted: $isMuted,
                    onPlayPause: onPlayPause,
                    onSeek: onSeek,
                    onSkipBackward: onSkipBackward,
                    onSkipForward: onSkipForward
                )

                Divider()
                    .padding(.horizontal, 8)

                OpacityControlView(opacity: $opacity)
            }
            .padding()
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding()
        }
    }
}

#Preview {
    ZStack {
        Color.black

        VideoControlsOverlay(
            opacity: .constant(0.5),
            isPlaying: .constant(false),
            currentTime: .constant(CMTime(seconds: 30, preferredTimescale: 600)),
            duration: .constant(CMTime(seconds: 180, preferredTimescale: 600)),
            isMuted: .constant(false),
            onPlayPause: {},
            onSeek: { _ in },
            onSkipBackward: {},
            onSkipForward: {}
        )
    }
    .frame(width: 600, height: 400)
}
