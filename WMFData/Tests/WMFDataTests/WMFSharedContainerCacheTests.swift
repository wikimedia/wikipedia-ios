import XCTest
@testable import WMFData

final class WMFSharedContainerCacheTests: XCTestCase {

    private struct MockObject: Codable, Equatable {
        let title: String
        let count: Int
    }

    private var containerURL: URL!

    override func setUpWithError() throws {
        try super.setUpWithError()
        containerURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: containerURL, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: containerURL)
        containerURL = nil
        try super.tearDownWithError()
    }

    // MARK: - WMFSharedContainerCache

    func testSaveAndLoadInContainerRoot() {
        let cache = WMFSharedContainerCache(fileName: "Root File", containerURL: containerURL)
        let object = MockObject(title: "Root", count: 1)

        cache.saveCache(object)

        let loaded: MockObject? = cache.loadCache()
        XCTAssertEqual(loaded, object)
        XCTAssertTrue(FileManager.default.fileExists(atPath: containerURL.appendingPathComponent("Root File.json").path))
    }

    func testSaveCreatesSubdirectory() {
        let cache = WMFSharedContainerCache(fileName: "Nested File", subdirectoryPathComponent: "Nested", containerURL: containerURL)
        let object = MockObject(title: "Nested", count: 2)

        cache.saveCache(object)

        let loaded: MockObject? = cache.loadCache()
        XCTAssertEqual(loaded, object)
        XCTAssertTrue(FileManager.default.fileExists(atPath: containerURL.appendingPathComponent("Nested/Nested File.json").path))
    }

    func testLoadMissingFileReturnsNil() {
        let cache = WMFSharedContainerCache(fileName: "Missing", containerURL: containerURL)
        let loaded: MockObject? = cache.loadCache()
        XCTAssertNil(loaded)
    }

    func testRemoveCache() throws {
        let cache = WMFSharedContainerCache(fileName: "Removed", containerURL: containerURL)
        cache.saveCache(MockObject(title: "Removed", count: 3))

        try cache.removeCache()

        let loaded: MockObject? = cache.loadCache()
        XCTAssertNil(loaded)
    }

    func testNilContainerURLDoesNothing() {
        let cache = WMFSharedContainerCache(fileName: "No Container", containerURL: nil)

        cache.saveCache(MockObject(title: "No Container", count: 4))

        let loaded: MockObject? = cache.loadCache()
        XCTAssertNil(loaded)
        XCTAssertThrowsError(try cache.removeCache())
        XCTAssertEqual(WMFSharedContainerCache.fileNames(inSubdirectory: "Any", containerURL: nil), [])
    }

    func testFileNamesInSubdirectory() {
        for name in ["First", "Second"] {
            WMFSharedContainerCache(fileName: name, subdirectoryPathComponent: "Listed", containerURL: containerURL)
                .saveCache(MockObject(title: name, count: 0))
        }
        WMFSharedContainerCache(fileName: "Elsewhere", subdirectoryPathComponent: "Other", containerURL: containerURL)
            .saveCache(MockObject(title: "Elsewhere", count: 0))

        let fileNames = WMFSharedContainerCache.fileNames(inSubdirectory: "Listed", containerURL: containerURL)

        XCTAssertEqual(Set(fileNames), ["First", "Second"])
    }

    func testDeleteStaleCachedItemsKeepsMostRecent() throws {
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
        XCTAssertEqual(Set(remaining), ["Item 3", "Item 4"])
    }

    func testDeleteStaleCachedItemsWithZeroDeletesAll() {
        for index in 0..<3 {
            WMFSharedContainerCache(fileName: "Item \(index)", subdirectoryPathComponent: "Stale", containerURL: containerURL)
                .saveCache(MockObject(title: "Item", count: index))
        }

        WMFSharedContainerCache.deleteStaleCachedItems(in: "Stale", keepingMostRecent: 0, containerURL: containerURL)

        XCTAssertEqual(WMFSharedContainerCache.fileNames(inSubdirectory: "Stale", containerURL: containerURL), [])
    }

    // MARK: - WMFSharedContainerCacheStore

    func testStoreSingleKeyUsesContainerRoot() throws {
        let store = WMFSharedContainerCacheStore(containerURL: containerURL)
        let object = MockObject(title: "Single", count: 5)

        try store.save(key: "Single Key", value: object)

        let loaded: MockObject? = try store.load(key: "Single Key")
        XCTAssertEqual(loaded, object)
        XCTAssertTrue(FileManager.default.fileExists(atPath: containerURL.appendingPathComponent("Single Key.json").path))
    }

    func testStoreTwoPartKeyUsesSubdirectory() throws {
        let store = WMFSharedContainerCacheStore(containerURL: containerURL)
        let object = MockObject(title: "Double", count: 6)

        try store.save(key: "Directory", "File", value: object)

        let loaded: MockObject? = try store.load(key: "Directory", "File")
        XCTAssertEqual(loaded, object)
        XCTAssertEqual(try store.keys(inDirectory: "Directory"), ["File"])
    }

    func testStoreRemove() throws {
        let store = WMFSharedContainerCacheStore(containerURL: containerURL)
        try store.save(key: "Directory", "File", value: MockObject(title: "Removed", count: 7))

        try store.remove(key: "Directory", "File")

        let loaded: MockObject? = try store.load(key: "Directory", "File")
        XCTAssertNil(loaded)
        XCTAssertNoThrow(try store.remove(key: "Directory", "File"), "Removing a missing file must not throw")
    }

    func testStoreRejectsUnexpectedKeyCount() {
        let store = WMFSharedContainerCacheStore(containerURL: containerURL)
        let object = MockObject(title: "Bad", count: 8)

        XCTAssertThrowsError(try store.save(key: "A", "B", "C", value: object))
        XCTAssertThrowsError(try { let _: MockObject? = try store.load(key: "A", "B", "C") }())
        XCTAssertThrowsError(try store.remove(key: "A", "B", "C"))
        XCTAssertThrowsError(try store.remove())
    }
}
