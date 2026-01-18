import SwiftUI

/// Scenario Writer メインウィンドウ
struct ScenarioWriterWindow: View {
    @Environment(AppState.self) private var appState
    @State private var selectedTab: ScenarioWriterTab = .pipeline

    var body: some View {
        NavigationSplitView {
            ScenarioWriterSidebar(selection: $selectedTab)
                .navigationSplitViewColumnWidth(min: 180, ideal: 200, max: 250)
        } detail: {
            contentView
                .navigationTitle(selectedTab.rawValue)
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
    private var contentView: some View {
        switch selectedTab {
        case .pipeline:
            PipelineTab()
        case .routeGenerate:
            RouteGenerateTab()
        case .scenarioGenerate:
            ScenarioGenerateTab()
        case .scenarioIntegrate:
            ScenarioIntegrateTab()
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
