import SwiftUI

struct RadiusPicker: View {
    @Binding var selectedRadius: SearchRadius

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("検索範囲")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            HStack(spacing: 12) {
                ForEach(SearchRadius.allCases) { radius in
                    Button {
                        selectedRadius = radius
                    } label: {
                        Text(radius.label)
                            .font(.subheadline)
                            .fontWeight(selectedRadius == radius ? .semibold : .regular)
                            .foregroundStyle(selectedRadius == radius ? .white : .primary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background {
                                if selectedRadius == radius {
                                    Capsule()
                                        .fill(Color.accentColor)
                                } else {
                                    Capsule()
                                        .strokeBorder(Color.secondary.opacity(0.3), lineWidth: 1)
                                }
                            }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

#Preview {
    @Previewable @State var radius: SearchRadius = .large
    RadiusPicker(selectedRadius: $radius)
        .padding()
}
