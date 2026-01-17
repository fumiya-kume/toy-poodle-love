import SwiftUI

struct CategoryChips: View {
    @Binding var selectedCategories: Set<PlanCategory>

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(PlanCategory.allCases) { category in
                Button {
                    toggleCategory(category)
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: category.icon)
                            .font(.title2)
                            .foregroundStyle(category.color)
                            .frame(width: 32)

                        Text(category.rawValue)
                            .font(.body)
                            .foregroundStyle(.primary)

                        Spacer()

                        if selectedCategories.contains(category) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(Color.accentColor)
                        }
                    }
                    .padding()
                    .background {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.secondarySystemBackground))
                            .overlay {
                                if selectedCategories.contains(category) {
                                    RoundedRectangle(cornerRadius: 12)
                                        .strokeBorder(Color.accentColor, lineWidth: 2)
                                }
                            }
                    }
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func toggleCategory(_ category: PlanCategory) {
        if selectedCategories.contains(category) {
            selectedCategories.remove(category)
        } else {
            selectedCategories.insert(category)
        }
    }
}

#Preview {
    @Previewable @State var selected: Set<PlanCategory> = [.scenic]
    CategoryChips(selectedCategories: $selected)
        .padding()
}
