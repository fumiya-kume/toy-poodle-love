import SwiftUI
import SwiftData

@main
struct handheldApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: Item.self)
    }
}
