import Foundation
import Testing
@testable import WMFData

/// Swift Testing makes a new instance for each test. Thus each test gets its own temporary container.
@Suite
final class WMFSharedContainerCacheTests {

    private struct MockObject: Codable, Equatable {
        let title: String
        let count: Int
    }

    private let containerURL: URL

    init() throws {
        containerURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: containerURL, withIntermediateDirectories: true)
    }

    deinit {
        try? FileManager.default.removeItem(at: containerURL)
    }

    // MARK: - WMFSharedContainerCache

    @Test
    func saveAndLoadInContainerRoot() {
        let cache = WMFSharedContainerCache(fileName: "Root File", containerURL: containerURL)
        let object = MockObject(title: "Root", count: 1)

        cache.saveCache(object)

        let loaded: MockObject? = cache.loadCache()
        #expect(loaded == object)
        #expect(FileManager.default.fileExists(atPath: containerURL.appendingPathComponent("Root File.json").path))
    }

    @Test
    func saveCreatesSubdirectory() {
        let cache = WMFSharedContainerCache(fileName: "Nested File", subdirectoryPathComponent: "Nested", containerURL: containerURL)
        let object = MockObject(title: "Nested", count: 2)

        cache.saveCache(object)

        let loaded: MockObject? = cache.loadCache()
        #expect(loaded == object)
        #expect(FileManager.default.fileExists(atPath: containerURL.appendingPathComponent("Nested/Nested File.json").path))
    }

    @Test
    func loadMissingFileReturnsNil() {
        let cache = WMFSharedContainerCache(fileName: "Missing", containerURL: containerURL)
        let loaded: MockObject? = cache.loadCache()
        #expect(loaded == nil)
    }

    @Test
    func removeCache() throws {
        let cache = WMFSharedContainerCache(fileName: "Removed", containerURL: containerURL)
        cache.saveCache(MockObject(title: "Removed", count: 3))

        try cache.removeCache()

        let loaded: MockObject? = cache.loadCache()
        #expect(loaded == nil)
    }

    @Test
    func nilContainerURLDoesNothing() {
        let cache = WMFSharedContainerCache(fileName: "No Container", containerURL: nil)

        cache.saveCache(MockObject(title: "No Container", count: 4))

        let loaded: MockObject? = cache.loadCache()
        #expect(loaded == nil)
        #expect(throws: WMFSharedContainerCacheError.self) { try cache.removeCache() }
        #expect(WMFSharedContainerCache.fileNames(inSubdirectory: "Any", containerURL: nil).isEmpty)
    }

    @Test
    func fileNamesInSubdirectory() {
        for name in ["First", "Second"] {
            WMFSharedContainerCache(fileName: name, subdirectoryPathComponent: "Listed", containerURL: containerURL)
                .saveCache(MockObject(title: name, count: 0))
        }
        WMFSharedContainerCache(fileName: "Elsewhere", subdirectoryPathComponent: "Other", containerURL: containerURL)
            .saveCache(MockObject(title: "Elsewhere", count: 0))

        let fileNames = WMFSharedContainerCache.fileNames(inSubdirectory: "Listed", containerURL: containerURL)

        #expect(Set(fileNames) == ["First", "Second"])
    }

    @Test
    func deleteStaleCachedItemsKeepsMostRecent() throws {
        let now = Date()
        for index in 0..<5 {
            let name = "Item \(index)"
            WMFSharedContainerCache(fileName: name, subdirectoryPathComponent: "Stale", containerURL: containerURL)
                .saveCache(MockObject(title: name, count: index))
            // A higher index is more recent.
            let fileURL = containerURL.appendingPathComponent("Stale/\(name).json")
            try FileManager.default.setAttributes([.modificationDate: now.addingTimeInterval(TimeInterval(index))], ofItemAtPath: fileURL.path)
        }

        WMFSharedContainerCache.deleteStaleCachedItems(in: "Stale", keepingMostRecent: 2, containerURL: containerURL)

        let remaining = WMFSharedContainerCache.fileNames(inSubdirectory: "Stale", containerURL: containerURL)
        #expect(Set(remaining) == ["Item 3", "Item 4"])
    }

    @Test
    func deleteStaleCachedItemsWithZeroDeletesAll() {
        for index in 0..<3 {
            WMFSharedContainerCache(fileName: "Item \(index)", subdirectoryPathComponent: "Stale", containerURL: containerURL)
                .saveCache(MockObject(title: "Item", count: index))
        }

        WMFSharedContainerCache.deleteStaleCachedItems(in: "Stale", keepingMostRecent: 0, containerURL: containerURL)

        #expect(WMFSharedContainerCache.fileNames(inSubdirectory: "Stale", containerURL: containerURL).isEmpty)
    }

    // MARK: - WMFSharedContainerCacheStore

    @Test
    func storeSingleKeyUsesContainerRoot() throws {
        let store = WMFSharedContainerCacheStore(containerURL: containerURL)
        let object = MockObject(title: "Single", count: 5)

        try store.save(key: "Single Key", value: object)

        let loaded: MockObject? = try store.load(key: "Single Key")
        #expect(loaded == object)
        #expect(FileManager.default.fileExists(atPath: containerURL.appendingPathComponent("Single Key.json").path))
    }

    @Test
    func storeTwoPartKeyUsesSubdirectory() throws {
        let store = WMFSharedContainerCacheStore(containerURL: containerURL)
        let object = MockObject(title: "Double", count: 6)

        try store.save(key: "Directory", "File", value: object)

        let loaded: MockObject? = try store.load(key: "Directory", "File")
        #expect(loaded == object)
        #expect(try store.keys(inDirectory: "Directory") == ["File"])
    }

    @Test
    func storeRemove() throws {
        let store = WMFSharedContainerCacheStore(containerURL: containerURL)
        try store.save(key: "Directory", "File", value: MockObject(title: "Removed", count: 7))

        try store.remove(key: "Directory", "File")

        let loaded: MockObject? = try store.load(key: "Directory", "File")
        #expect(loaded == nil)
        #expect(throws: Never.self, "Removing a missing file must not throw") {
            try store.remove(key: "Directory", "File")
        }
    }

    @Test
    func storeRejectsUnexpectedKeyCount() {
        let store = WMFSharedContainerCacheStore(containerURL: containerURL)
        let object = MockObject(title: "Bad", count: 8)

        #expect(throws: WMFSharedContainerCacheStoreError.unexpectedKeyCount) {
            try store.save(key: "A", "B", "C", value: object)
        }
        #expect(throws: WMFSharedContainerCacheStoreError.unexpectedKeyCount) {
            let _: MockObject? = try store.load(key: "A", "B", "C")
        }
        #expect(throws: WMFSharedContainerCacheStoreError.unexpectedKeyCount) {
            try store.remove(key: "A", "B", "C")
        }
        #expect(throws: WMFSharedContainerCacheStoreError.unexpectedKeyCount) {
            try store.remove()
        }
    }
}
