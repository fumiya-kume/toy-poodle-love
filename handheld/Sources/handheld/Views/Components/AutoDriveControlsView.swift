import SwiftUI

struct AutoDriveControlsView: View {
    let isPlaying: Bool
    let speed: AutoDriveSpeed
    let progress: Double
    let currentIndex: Int
    let totalPoints: Int

    var onPlayPause: () -> Void
    var onStop: () -> Void
    var onSpeedChange: (AutoDriveSpeed) -> Void
    var onSeek: (Double) -> Void

    @State private var isDragging = false
    @State private var dragProgress: Double = 0

    var body: some View {
        VStack(spacing: 12) {
            seekableProgressBar

            HStack(spacing: 24) {
                stopButton
                playPauseButton
                speedMenu
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
    }

    private var seekableProgressBar: some View {
        VStack(spacing: 4) {
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color(.systemGray4))
                        .frame(height: 8)
                        .cornerRadius(4)

                    Rectangle()
                        .fill(Color.blue)
                        .frame(width: geometry.size.width * (isDragging ? dragProgress : progress), height: 8)
                        .cornerRadius(4)

                    Circle()
                        .fill(Color.blue)
                        .frame(width: 20, height: 20)
                        .offset(x: geometry.size.width * (isDragging ? dragProgress : progress) - 10)
                        .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
                }
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            isDragging = true
                            let newProgress = min(max(value.location.x / geometry.size.width, 0), 1)
                            dragProgress = newProgress
                        }
                        .onEnded { value in
                            isDragging = false
                            let finalProgress = min(max(value.location.x / geometry.size.width, 0), 1)
                            onSeek(finalProgress)
                        }
                )
                .onTapGesture { location in
                    let tapProgress = min(max(location.x / geometry.size.width, 0), 1)
                    onSeek(tapProgress)
                }
            }
            .frame(height: 20)

            HStack {
                Text("\(currentIndex + 1)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Spacer()
                Text("\(totalPoints)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }

    private var stopButton: some View {
        Button(action: onStop) {
            Image(systemName: "stop.fill")
                .font(.title2)
                .foregroundColor(.red)
        }
    }

    private var playPauseButton: some View {
        Button(action: onPlayPause) {
            Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                .font(.title)
                .foregroundColor(.blue)
                .frame(width: 44, height: 44)
                .background(Color.blue.opacity(0.1))
                .clipShape(Circle())
        }
    }

    private var speedMenu: some View {
        Menu {
            ForEach(AutoDriveSpeed.allCases) { speedOption in
                Button {
                    onSpeedChange(speedOption)
                } label: {
                    Label(speedOption.rawValue, systemImage: speedOption.icon)
                }
            }
        } label: {
            HStack {
                Image(systemName: speed.icon)
                Text(speed.rawValue)
                    .font(.caption)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color(.systemGray5))
            .cornerRadius(8)
        }
    }
}
