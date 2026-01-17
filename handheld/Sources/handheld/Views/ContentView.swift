import SwiftUI

struct ContentView: View {
    @State private var viewModel = ContentViewModel()

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Text(viewModel.message)
                    .font(.title)

                NavigationLink {
                    LocationSearchView()
                } label: {
                    Label("場所を検索", systemImage: "magnifyingglass")
                        .font(.headline)
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            .navigationTitle("Toy Poodle Love")
        }
    }
}

#Preview {
    ContentView()
}
