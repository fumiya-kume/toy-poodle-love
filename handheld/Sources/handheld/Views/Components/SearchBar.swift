import SwiftUI

struct SearchBar: View {
    @Binding var text: String
    var placeholder: String = "場所を入力..."
    var onSearch: () -> Void
    var onTextChange: ((String) -> Void)?

    var body: some View {
        HStack {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)

                TextField(placeholder, text: $text)
                    .textFieldStyle(.plain)
                    .autocorrectionDisabled()
                    .onSubmit {
                        onSearch()
                    }
                    .onChange(of: text) { _, newValue in
                        onTextChange?(newValue)
                    }

                if !text.isEmpty {
                    Button {
                        text = ""
                        onTextChange?("")
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(10)
            .background(Color(.systemGray6))
            .cornerRadius(10)

            Button("検索") {
                onSearch()
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: 500)
        .padding(.horizontal)
    }
}

#Preview {
    SearchBar(text: .constant("東京駅")) {
        // no-op
    }
}
