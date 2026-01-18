import SwiftUI
import Observation

struct VideoControlsOverlay: View {
    @Binding var opacity: Double
    @Bindable var playbackController: PlaybackController
    let hasOverlay: Bool

    var body: some View {
        VStack {
            Spacer()

            VStack(spacing: 12) {
                DualProgressControlBar(
                    isPlaying: playbackController.isPlaying,
                    mainState: playbackController.mainVideoState,
                    overlayState: playbackController.overlayVideoState,
                    hasOverlay: hasOverlay,
                    isMuted: $playbackController.isMuted,
                    onPlayPause: playbackController.togglePlayPause,
                    onMainPlayPause: playbackController.toggleMainPlayPause,
                    onOverlayPlayPause: playbackController.toggleOverlayPlayPause,
                    onSeekMain: playbackController.seekMain(to:),
                    onSeekOverlay: playbackController.seekOverlay(to:),
                    onSkipBackward: { playbackController.skipBackward() },
                    onSkipForward: { playbackController.skipForward() },
                    onSyncOverlay: playbackController.syncOverlayToMain
                )

                Divider()
                    .padding(.horizontal, 8)

                OpacityControlView(opacity: $opacity)
            }
            .padding()
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .contentShape(Rectangle())
            .onTapGesture { } // Consume tap to prevent propagation to video player
            .padding()
        }
    }
}

#Preview {
    ZStack {
        Color.black

        VideoControlsOverlay(
            opacity: .constant(0.5),
            playbackController: PlaybackController(),
            hasOverlay: true
        )
    }
    .frame(width: 600, height: 400)
}
