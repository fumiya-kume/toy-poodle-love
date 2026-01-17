import SwiftUI
import SwiftData

@main
struct handheldApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: Item.self)
        #if targetEnvironment(macCatalyst)
        .defaultSize(width: 1200, height: 800)
        #endif
    }
}
