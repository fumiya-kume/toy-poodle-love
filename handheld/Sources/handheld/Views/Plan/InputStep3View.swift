import SwiftUI

struct InputStep3View: View {
    @Bindable var viewModel: PlanGeneratorViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("テーマを設定しましょう")
                    .font(.title2)
                    .fontWeight(.bold)

                VStack(alignment: .leading, spacing: 16) {
                    Text("おすすめテーマ")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    ThemeSuggestionChips(
                        categories: viewModel.selectedCategories,
                        onSelect: { suggestion in
                            viewModel.selectThemeSuggestion(suggestion)
                        }
                    )
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("自由入力")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    TextField("例: 歴史を感じる城下町巡り", text: $viewModel.theme)
                        .textFieldStyle(.plain)
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                VStack(alignment: .leading, spacing: 12) {
                    Toggle("開始時刻を設定", isOn: $viewModel.useStartTime)

                    if viewModel.useStartTime {
                        DatePicker(
                            "開始時刻",
                            selection: Binding(
                                get: { viewModel.startTime ?? Date() },
                                set: { viewModel.startTime = $0 }
                            ),
                            displayedComponents: .hourAndMinute
                        )
                        .datePickerStyle(.compact)
                    }
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))

                Spacer(minLength: 100)
            }
        }
    }
}

#Preview {
    @Previewable @State var vm = PlanGeneratorViewModel()
    InputStep3View(viewModel: vm)
        .padding()
        .onAppear {
            vm.selectedCategories = [.scenic, .activity]
        }
}
