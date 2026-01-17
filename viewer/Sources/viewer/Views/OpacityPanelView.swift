import SwiftUI

/// Opacity Control Panelのコンテンツビュー
struct OpacityPanelView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        VStack(spacing: 8) {
            OpacityControlView(opacity: appState.opacityPanelController.opacityBinding)
        }
        .padding()
        .frame(minWidth: 200, minHeight: 60)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Overlay Opacity Control")
    }
}

#Preview {
    OpacityPanelView()
        .environment(AppState())
        .frame(width: 280, height: 80)
}
