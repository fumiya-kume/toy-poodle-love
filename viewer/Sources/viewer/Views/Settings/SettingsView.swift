import SwiftUI

struct SettingsView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        Form {
            Section("Playback") {
                Toggle(
                    "Auto-play on launch",
                    isOn: Binding(
                        get: { appState.appSettings.autoPlayOnLaunch },
                        set: {
                            appState.appSettings.autoPlayOnLaunch = $0
                            appState.save()
                        }
                    )
                )
            }

            Section("Controls") {
                Toggle(
                    "Show controls on hover",
                    isOn: Binding(
                        get: { appState.appSettings.showControlsOnHover },
                        set: {
                            appState.appSettings.showControlsOnHover = $0
                            appState.save()
                        }
                    )
                )

                HStack {
                    Text("Control hide delay")
                    Spacer()
                    Picker(
                        "",
                        selection: Binding(
                            get: { appState.appSettings.controlHideDelay },
                            set: {
                                appState.appSettings.controlHideDelay = $0
                                appState.save()
                            }
                        )
                    ) {
                        Text("1 second").tag(1.0)
                        Text("2 seconds").tag(2.0)
                        Text("3 seconds").tag(3.0)
                        Text("5 seconds").tag(5.0)
                    }
                    .labelsHidden()
                    .frame(width: 120)
                }
            }
        }
        .formStyle(.grouped)
        .padding()
        .frame(width: 400, height: 200)
    }
}

#Preview {
    SettingsView()
        .environment(AppState())
}
