import SwiftUI
import AVFoundation

struct VideoProgressBar: View {
    let label: String
    let labelColor: Color
    let currentTime: CMTime
    let duration: CMTime
    var onSeek: (CMTime) -> Void

    @State private var isDragging = false
    @State private var dragProgress: Double = 0

    private var hasDuration: Bool {
        duration.isValid && !duration.isIndefinite && duration.seconds > 0
    }

    private var progress: Double {
        guard hasDuration else { return 0 }
        let value = isDragging ? dragProgress : currentTime.seconds / duration.seconds
        return min(max(value, 0), 1)
    }

    private var displayTime: CMTime {
        guard hasDuration, isDragging else { return currentTime }
        return CMTime(seconds: dragProgress * duration.seconds, preferredTimescale: 600)
    }

    var body: some View {
        HStack(spacing: 12) {
            HStack(spacing: 6) {
                Circle()
                    .fill(labelColor)
                    .frame(width: 8, height: 8)

                Text(label)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(labelColor)
            }
            .frame(minWidth: 70, alignment: .leading)

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
                    let clampedProgress = min(max(dragProgress, 0), 1)
                    let seconds = hasDuration ? clampedProgress * duration.seconds : 0
                    let newTime = CMTime(seconds: seconds, preferredTimescale: 600)
                    onSeek(newTime)
                    isDragging = false
                }
            }
            .tint(labelColor)
            .disabled(!hasDuration)
            .frame(minWidth: 160)

            Text("\(displayTime.formattedString) / \(duration.formattedString)")
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(.secondary)
                .monospacedDigit()
                .frame(minWidth: 90, alignment: .trailing)
        }
    }
}

#Preview {
    VStack(spacing: 12) {
        VideoProgressBar(
            label: "Main",
            labelColor: .blue,
            currentTime: CMTime(seconds: 83, preferredTimescale: 600),
            duration: CMTime(seconds: 300, preferredTimescale: 600),
            onSeek: { _ in }
        )

        VideoProgressBar(
            label: "Overlay",
            labelColor: .orange,
            currentTime: CMTime(seconds: 48, preferredTimescale: 600),
            duration: CMTime(seconds: 210, preferredTimescale: 600),
            onSeek: { _ in }
        )
    }
    .padding()
    .background(.ultraThinMaterial)
    .clipShape(RoundedRectangle(cornerRadius: 12))
    .frame(width: 420)
}
