import SwiftUI

/// Scenario Writerのサイドバーナビゲーション
enum ScenarioWriterTab: String, CaseIterable, Identifiable {
    case pipeline = "Pipeline"
    case routeGenerate = "ルート生成"
    case scenarioGenerate = "シナリオ生成"
    case scenarioIntegrate = "シナリオ統合"
    case textGeneration = "テキスト生成"
    case geocode = "ジオコーディング"
    case routeOptimize = "ルート最適化"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .pipeline:
            return "arrow.triangle.branch"
        case .routeGenerate:
            return "map"
        case .scenarioGenerate:
            return "text.bubble"
        case .scenarioIntegrate:
            return "sparkles"
        case .textGeneration:
            return "text.alignleft"
        case .geocode:
            return "mappin.and.ellipse"
        case .routeOptimize:
            return "point.topright.filled.arrow.triangle.backward.to.point.bottomleft"
        }
    }
}

struct ScenarioWriterSidebar: View {
    @Binding var selection: ScenarioWriterTab

    var body: some View {
        List(selection: $selection) {
            Section("メイン") {
                ForEach([ScenarioWriterTab.pipeline, .routeGenerate, .scenarioGenerate, .scenarioIntegrate], id: \.self) { tab in
                    Label(tab.rawValue, systemImage: tab.icon)
                        .tag(tab)
                }
            }

            Section("ツール") {
                ForEach([ScenarioWriterTab.textGeneration, .geocode, .routeOptimize], id: \.self) { tab in
                    Label(tab.rawValue, systemImage: tab.icon)
                        .tag(tab)
                }
            }
        }
        .listStyle(.sidebar)
    }
}

#Preview {
    @Previewable @State var selection: ScenarioWriterTab = .pipeline
    ScenarioWriterSidebar(selection: $selection)
        .frame(width: 200)
}
