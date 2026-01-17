import SwiftUI
import SwiftData

@main
struct HandheldApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [Item.self, SightseeingPlan.self, PlanSpot.self, FavoriteSpot.self])
        #if targetEnvironment(macCatalyst)
        .defaultSize(width: 1200, height: 800)
        #endif
    }
}
