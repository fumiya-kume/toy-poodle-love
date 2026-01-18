import SwiftUI

/// AIモデル選択ピッカー
struct ModelPickerView: View {
    @Binding var selection: AIModel
    var label: String = "AIモデル"

    var body: some View {
        Picker(label, selection: $selection) {
            ForEach(AIModel.allCases) { model in
                Text(model.displayName).tag(model)
            }
        }
        .pickerStyle(.segmented)
    }
}

#Preview {
    @Previewable @State var model: AIModel = .gemini
    ModelPickerView(selection: $model)
        .padding()
}
