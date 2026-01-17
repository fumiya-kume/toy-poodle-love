import SwiftUI

struct CategoryIconView: View {
    let category: SuggestionCategory
    var size: CGFloat = 32

    var body: some View {
        ZStack {
            Circle()
                .fill(category.backgroundColor)
                .frame(width: size, height: size)

            Image(systemName: category.icon)
                .font(.system(size: size * 0.45))
                .foregroundColor(.white)
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        ForEach(SuggestionCategory.allCases, id: \.self) { category in
            HStack {
                CategoryIconView(category: category)
                Text(category.rawValue)
            }
        }
    }
    .padding()
}
