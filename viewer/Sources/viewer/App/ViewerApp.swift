import SwiftUI

@main
struct ViewerApp: App {
    @State private var appState: AppState = AppState()

    var body: some Scene {
        WindowGroup("Video Player") {
            VideoPlayerWindow()
                .environment(appState)
        }
        .defaultSize(width: 800, height: 600)
        .commands {
            CommandGroup(after: .newItem) {
                Button("New Video Window") {
                    // Cmd+N で新しいウィンドウが開く（デフォルト動作）
                }
                .keyboardShortcut("n", modifiers: .command)
                .hidden()
            }

            CommandMenu("View") {
                Button(appState.opacityPanelController.isVisible
                       ? "Hide Opacity Panel"
                       : "Show Opacity Panel") {
                    appState.opacityPanelController.toggle()
                }
                .keyboardShortcut("o", modifiers: [.command, .shift])
            }

            CommandMenu("Playback") {
                Button("Play/Pause") {
                    appState.playbackController.togglePlayPause()
                }
                .keyboardShortcut(.space, modifiers: [])

                Divider()

                Button("Skip Backward 10s") {
                    appState.playbackController.skipBackward()
                }
                .keyboardShortcut(.leftArrow, modifiers: [])

                Button("Skip Forward 10s") {
                    appState.playbackController.skipForward()
                }
                .keyboardShortcut(.rightArrow, modifiers: [])

                Divider()

                Button("Go to Beginning") {
                    appState.playbackController.goToBeginning()
                }
                .keyboardShortcut(.leftArrow, modifiers: .command)

                Button(appState.playbackController.isMuted ? "Unmute" : "Mute") {
                    appState.playbackController.isMuted.toggle()
                }
                .keyboardShortcut("m", modifiers: [])

                Divider()

                Button("Increase Overlay Opacity") {
                    appState.opacityPanelController.increaseOpacity(by: 0.1)
                }
                .keyboardShortcut("]", modifiers: .command)

                Button("Decrease Overlay Opacity") {
                    appState.opacityPanelController.decreaseOpacity(by: 0.1)
                }
                .keyboardShortcut("[", modifiers: .command)
            }
        }

        Settings {
            SettingsView()
                .environment(appState)
        }
    }
}
