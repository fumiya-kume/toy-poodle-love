import Foundation

actor BookmarkManager {
    static let shared = BookmarkManager()

    private init() {}

    func createBookmark(for url: URL) throws -> Data {
        try url.bookmarkData(
            options: .withSecurityScope,
            includingResourceValuesForKeys: nil,
            relativeTo: nil
        )
    }

    func resolveBookmark(_ bookmark: Data) throws -> (url: URL, isStale: Bool) {
        var isStale = false
        let url = try URL(
            resolvingBookmarkData: bookmark,
            options: .withSecurityScope,
            relativeTo: nil,
            bookmarkDataIsStale: &isStale
        )
        return (url, isStale)
    }

    func refreshBookmarkIfNeeded(_ bookmark: Data) throws -> Data? {
        let (url, isStale) = try resolveBookmark(bookmark)
        if isStale {
            return try createBookmark(for: url)
        }
        return nil
    }

    func startAccessing(bookmark: Data) -> URL? {
        var isStale = false
        guard let url = try? URL(
            resolvingBookmarkData: bookmark,
            options: .withSecurityScope,
            relativeTo: nil,
            bookmarkDataIsStale: &isStale
        ) else {
            return nil
        }
        guard url.startAccessingSecurityScopedResource() else {
            return nil
        }
        return url
    }

    func stopAccessing(url: URL) {
        url.stopAccessingSecurityScopedResource()
    }
}
