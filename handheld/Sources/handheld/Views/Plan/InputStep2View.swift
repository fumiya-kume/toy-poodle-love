import SwiftUI

struct InputStep2View: View {
    @Bindable var viewModel: PlanGeneratorViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("どんな観光がしたいですか？")
                .font(.title2)
                .fontWeight(.bold)

            Text("複数選択できます")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            CategoryChips(selectedCategories: $viewModel.selectedCategories)

            Spacer()
        }
    }
}

#Preview {
    InputStep2View(viewModel: PlanGeneratorViewModel())
        .padding()
}
