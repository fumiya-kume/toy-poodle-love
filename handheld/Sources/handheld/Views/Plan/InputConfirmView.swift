import SwiftUI

struct InputConfirmView: View {
    @Bindable var viewModel: PlanGeneratorViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("内容を確認してください")
                .font(.title2)
                .fontWeight(.bold)

            VStack(spacing: 16) {
                ConfirmRow(
                    icon: "mappin.circle.fill",
                    iconColor: .red,
                    label: "エリア",
                    value: viewModel.selectedLocation?.name ?? "-",
                    subValue: viewModel.searchRadius.label
                )

                Divider()

                ConfirmRow(
                    icon: "tag.fill",
                    iconColor: .blue,
                    label: "カテゴリ",
                    value: viewModel.selectedCategories.map { $0.rawValue }.joined(separator: "、")
                )

                Divider()

                ConfirmRow(
                    icon: "lightbulb.fill",
                    iconColor: .orange,
                    label: "テーマ",
                    value: viewModel.theme
                )

                if viewModel.useStartTime, let startTime = viewModel.startTime {
                    Divider()

                    ConfirmRow(
                        icon: "clock.fill",
                        iconColor: .green,
                        label: "開始時刻",
                        value: formatTime(startTime)
                    )
                }
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))

            Spacer()
        }
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "H:mm"
        return formatter.string(from: date)
    }
}

struct ConfirmRow: View {
    let icon: String
    let iconColor: Color
    let label: String
    let value: String
    var subValue: String? = nil

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(iconColor)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 4) {
                Text(label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.body)
                if let subValue = subValue {
                    Text(subValue)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()
        }
    }
}

#Preview {
    @Previewable @State var vm = PlanGeneratorViewModel()
    InputConfirmView(viewModel: vm)
        .padding()
        .onAppear {
            vm.selectedCategories = [.scenic, .activity]
            vm.theme = "歴史巡り"
        }
}
