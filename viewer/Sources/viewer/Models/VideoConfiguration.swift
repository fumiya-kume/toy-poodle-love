import Foundation

struct VideoConfiguration: Identifiable, Codable, Sendable, Equatable {
    let id: UUID
    var windowIndex: Int
    var mainVideoBookmark: Data?
    var overlayVideoBookmark: Data?
    var overlayOpacity: Double

    init(
        id: UUID = UUID(),
        windowIndex: Int,
        mainVideoBookmark: Data? = nil,
        overlayVideoBookmark: Data? = nil,
        overlayOpacity: Double = 0.5
    ) {
        self.id = id
        self.windowIndex = windowIndex
        self.mainVideoBookmark = mainVideoBookmark
        self.overlayVideoBookmark = overlayVideoBookmark
        self.overlayOpacity = overlayOpacity
    }

    var mainVideoURL: URL? {
        guard let bookmark = mainVideoBookmark else { return nil }
        return Self.resolveBookmark(bookmark)
    }

    var overlayVideoURL: URL? {
        guard let bookmark = overlayVideoBookmark else { return nil }
        return Self.resolveBookmark(bookmark)
    }

    private static func resolveBookmark(_ bookmark: Data) -> URL? {
        var isStale = false
        do {
            let url = try URL(
                resolvingBookmarkData: bookmark,
                options: .withSecurityScope,
                relativeTo: nil,
                bookmarkDataIsStale: &isStale
            )
            return url
        } catch {
            return nil
        }
    }

    static func createBookmark(for url: URL) -> Data? {
        do {
            return try url.bookmarkData(
                options: .withSecurityScope,
                includingResourceValuesForKeys: nil,
                relativeTo: nil
            )
        } catch {
            return nil
        }
    }

    static func defaultConfigurations() -> [VideoConfiguration] {
        (0..<3).map { index in
            VideoConfiguration(windowIndex: index)
        }
    }
}
