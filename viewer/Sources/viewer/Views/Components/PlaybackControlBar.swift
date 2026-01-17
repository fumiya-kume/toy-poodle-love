import SwiftUI
import AVFoundation

struct PlaybackControlBar: View {
    @Binding var isPlaying: Bool
    @Binding var currentTime: CMTime
    @Binding var duration: CMTime
    @Binding var isMuted: Bool

    var onPlayPause: () -> Void
    var onSeek: (CMTime) -> Void
    var onSkipBackward: () -> Void
    var onSkipForward: () -> Void

    @State private var isDragging = false
    @State private var dragProgress: Double = 0

    private var progress: Double {
        guard duration.seconds > 0 else { return 0 }
        return isDragging ? dragProgress : currentTime.seconds / duration.seconds
    }

    var body: some View {
        VStack(spacing: 8) {
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

                Slider(
                    value: Binding(
                        get: { progress },
                        set: { newValue in
                            dragProgress = newValue
                            isDragging = true
                        }
                    ),
                    in: 0...1
                ) { editing in
                    if !editing && isDragging {
                        let newTime = CMTime(seconds: dragProgress * duration.seconds, preferredTimescale: 600)
                        onSeek(newTime)
                        isDragging = false
                    }
                }
                .frame(minWidth: 150)

                Button(action: onSkipForward) {
                    Image(systemName: "goforward.10")
                        .font(.system(size: 16))
                }
                .buttonStyle(.plain)

                Button(action: { isMuted.toggle() }) {
                    Image(systemName: isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                        .font(.system(size: 16))
                        .frame(width: 24)
                }
                .buttonStyle(.plain)
            }

            HStack {
                Text(currentTime.formattedString)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(.secondary)

                Spacer()

                Text(duration.formattedString)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }
}

#Preview {
    PlaybackControlBar(
        isPlaying: .constant(false),
        currentTime: .constant(CMTime(seconds: 30, preferredTimescale: 600)),
        duration: .constant(CMTime(seconds: 180, preferredTimescale: 600)),
        isMuted: .constant(false),
        onPlayPause: {},
        onSeek: { _ in },
        onSkipBackward: {},
        onSkipForward: {}
    )
    .padding()
    .background(.ultraThinMaterial)
    .clipShape(RoundedRectangle(cornerRadius: 12))
    .frame(width: 400)
}
