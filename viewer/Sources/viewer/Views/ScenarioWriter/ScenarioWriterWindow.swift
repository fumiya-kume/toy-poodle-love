import SwiftUI

/// Scenario Writer メインウィンドウ
struct ScenarioWriterWindow: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        @Bindable var bindableState = appState.scenarioWriterState
        NavigationSplitView {
            ScenarioWriterSidebar(selection: $bindableState.selectedTab)
                .navigationSplitViewColumnWidth(min: 180, ideal: 200, max: 250)
        } detail: {
            contentView(selectedTab: bindableState.selectedTab)
                .navigationTitle(bindableState.selectedTab.rawValue)
        }
        .alert(
            "エラー",
            isPresented: Binding(
                get: { appState.scenarioWriterState.showErrorAlert },
                set: { _ in appState.scenarioWriterState.dismissError() }
            )
        ) {
            Button("OK") {
                appState.scenarioWriterState.dismissError()
            }
        } message: {
            Text(appState.scenarioWriterState.lastError?.errorDescription ?? "不明なエラーが発生しました")
        }
    }

    @ViewBuilder
    private func contentView(selectedTab: ScenarioWriterTab) -> some View {
        switch selectedTab {
        case .pipeline:
            PipelineTab()
        case .routeGenerate:
            RouteGenerateTab()
        case .scenarioGenerate:
            ScenarioGenerateTab()
        case .scenarioIntegrate:
            ScenarioIntegrateTab()
        case .map:
            ScenarioMapTab()
        case .textGeneration:
            TextGenerationTab()
        case .geocode:
            GeocodeTab()
        case .routeOptimize:
            RouteOptimizeTab()
        }
    }
}

#Preview {
    ScenarioWriterWindow()
        .environment(AppState())
        .frame(width: 800, height: 600)
}
