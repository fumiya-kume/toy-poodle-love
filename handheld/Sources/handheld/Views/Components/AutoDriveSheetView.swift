import SwiftUI
import MapKit

struct AutoDriveSheetView: View {
    @Bindable var viewModel: LocationSearchViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase

    @State private var wasPlayingBeforeBackground = false

    var body: some View {
        VStack(spacing: 0) {
            headerView

            mainContent
        }
        .onChange(of: scenePhase) { _, newPhase in
            handleScenePhaseChange(newPhase)
        }
    }

    private var headerView: some View {
        HStack {
            Text("オートドライブ")
                .font(.headline)

            Spacer()

            Button("閉じる") {
                viewModel.stopAutoDrive()
                dismiss()
            }
        }
        .padding()
        .background(Color(.systemBackground))
    }

    @ViewBuilder
    private var mainContent: some View {
        switch viewModel.autoDriveConfiguration.state {
        case .idle:
            EmptyView()

        case .loading(let progress, let fetched, let total):
            AutoDriveLoadingView(
                progress: progress,
                fetchedCount: fetched,
                totalCount: total,
                points: viewModel.autoDrivePoints,
                route: viewModel.route,
                onCancel: {
                    viewModel.stopAutoDrive()
                    dismiss()
                }
            )

        case .playing, .paused:
            playbackView

        case .completed:
            completedView

        case .failed(let message):
            failedView(message: message)
        }
    }

    private var playbackView: some View {
        VStack(spacing: 0) {
            AutoDriveLookAroundView(
                scene: viewModel.currentAutoDriveScene,
                isLoading: false,
                pointIndex: viewModel.currentAutoDriveIndex,
                totalPoints: viewModel.autoDriveTotalPoints
            )

            AutoDriveControlsView(
                isPlaying: viewModel.autoDriveConfiguration.isPlaying,
                speed: viewModel.autoDriveConfiguration.speed,
                progress: viewModel.autoDriveProgress,
                currentIndex: viewModel.currentAutoDriveIndex,
                totalPoints: viewModel.autoDriveTotalPoints,
                onPlayPause: {
                    if viewModel.autoDriveConfiguration.isPlaying {
                        viewModel.pauseAutoDrive()
                    } else {
                        viewModel.resumeAutoDrive()
                    }
                },
                onStop: {
                    viewModel.stopAutoDrive()
                    dismiss()
                },
                onSpeedChange: { speed in
                    viewModel.setAutoDriveSpeed(speed)
                },
                onSeek: { progress in
                    let index = Int(progress * Double(viewModel.autoDriveTotalPoints - 1))
                    viewModel.seekAutoDrive(to: index)
                }
            )
            .padding(.bottom)
        }
    }

    private var completedView: some View {
        VStack(spacing: 20) {
            Spacer()

            Text("🎉")
                .font(.system(size: 64))

            Text("目的地に到着しました")
                .font(.title2)
                .fontWeight(.semibold)

            Button("閉じる") {
                viewModel.stopAutoDrive()
                dismiss()
            }
            .buttonStyle(.borderedProminent)

            Spacer()
        }
        .padding()
    }

    private func failedView(message: String) -> some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 64))
                .foregroundColor(.orange)

            Text(message)
                .font(.body)
                .multilineTextAlignment(.center)

            Button("閉じる") {
                viewModel.stopAutoDrive()
                dismiss()
            }
            .buttonStyle(.bordered)

            Spacer()
        }
        .padding()
    }

    private func handleScenePhaseChange(_ phase: ScenePhase) {
        switch phase {
        case .background:
            if viewModel.autoDriveConfiguration.isPlaying {
                wasPlayingBeforeBackground = true
                viewModel.pauseAutoDrive()
            }
        case .active:
            if wasPlayingBeforeBackground {
                wasPlayingBeforeBackground = false
                viewModel.resumeAutoDrive()
            }
        case .inactive:
            break
        @unknown default:
            break
        }
    }
}
