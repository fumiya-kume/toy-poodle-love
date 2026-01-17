import SwiftUI

struct ContentView: View {
    @State private var viewModel = ContentViewModel()

    var body: some View {
        VStack {
            Text(viewModel.message)
                .font(.title)
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
