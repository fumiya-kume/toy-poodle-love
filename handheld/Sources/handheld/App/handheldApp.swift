import SwiftUI
import SwiftData

@main
struct HandheldApp: App {
    private let modelContainer: ModelContainer

    init() {
        do {
            let schema = Schema([Item.self, SightseeingPlan.self, PlanSpot.self, FavoriteSpot.self])
            let storeURL = Self.defaultStoreURL()
            try Self.prepareStoreFile(at: storeURL)
            let configuration = ModelConfiguration(schema: schema, url: storeURL)
            modelContainer = try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Failed to create SwiftData ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(modelContainer)
        #if targetEnvironment(macCatalyst)
        .defaultSize(width: 1200, height: 800)
        #endif
    }
}

private extension HandheldApp {
    static func defaultStoreURL() -> URL {
        let applicationSupportDirectory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        return applicationSupportDirectory.appendingPathComponent("default.store")
    }

    static func prepareStoreFile(at storeURL: URL) throws {
        let directoryURL = storeURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)

        guard !FileManager.default.fileExists(atPath: storeURL.path) else {
            return
        }

        FileManager.default.createFile(atPath: storeURL.path, contents: nil)
    }
}
