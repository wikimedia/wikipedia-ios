import XCTest
@testable import Wikipedia
@testable import WMF

/// Thumbnails moved from upload.wikimedia.org to thumb.wikimedia.org (T427465). A saved article stores the
/// media list thumbnails under the thumb host; the gallery asks for the image info URL under the upload host.
final class PermanentlyPersistableURLCacheImageKeyTests: XCTestCase {

    private var dataStore: MWKDataStore!
    private var writer: ArticleCacheDBWriter!
    private var filesToRemove: [URL] = []

    override func setUp(completion: @escaping (Error?) -> Void) {
        MWKDataStore.createTemporaryDataStore(completion: { dataStore in
            self.dataStore = dataStore
            self.writer = dataStore.cacheController.articleCache.dbWriter as? ArticleCacheDBWriter
            completion(self.writer == nil ? RequestError.unknown : nil)
        })
    }

    override func tearDown() {
        super.tearDown()
        for url in filesToRemove {
            try? FileManager.default.removeItem(at: url)
        }
        dataStore.removeFolderAtBasePath()
    }

    private func imageRequest(_ string: String) throws -> URLRequest {
        let url = try XCTUnwrap(URL(string: string))
        return try XCTUnwrap(dataStore.session.urlRequestFromPersistence(with: url, persistType: .image))
    }

    private func itemKey(_ string: String) throws -> String {
        return try XCTUnwrap(dataStore.session.itemKeyForURLRequest(imageRequest(string)))
    }

    func testThumbHostAndUploadHostShareOneKey() throws {
        let thumbHost = try itemKey("https://thumb.wikimedia.org/wikipedia/commons/thumb/1/15/Cat.jpg/500px-Cat.jpg?utm_source=en.wikipedia.org&utm_campaign=parser&utm_content=thumbnail")
        let uploadHost = try itemKey("https://upload.wikimedia.org/wikipedia/commons/thumb/1/15/Cat.jpg/1280px-Cat.jpg")
        let original = try itemKey("https://upload.wikimedia.org/wikipedia/commons/1/15/Cat.jpg?utm_source=en.wikipedia.org&utm_campaign=imageinfo&utm_content=original")

        XCTAssertEqual(thumbHost, "upload.wikimedia.org__Cat.jpg")
        XCTAssertEqual(uploadHost, thumbHost)
        XCTAssertEqual(original, thumbHost, "The query items are not part of the key")
    }

    func testOtherHostsKeepTheirOwnKey() throws {
        XCTAssertEqual(try itemKey("https://example.org/wikipedia/commons/thumb/1/15/Cat.jpg/500px-Cat.jpg"), "example.org__Cat.jpg")
    }

    func testImageSavedUnderTheThumbHostIsServedForTheUploadHost() throws {
        // An article saved by an older app version wrote the key with the thumb host.
        let name = "\(UUID().uuidString).jpg"
        let legacyKey = "thumb.wikimedia.org__\(name)"
        let variant = "500"
        let legacyURL = try XCTUnwrap(URL(string: "https://thumb.wikimedia.org/wikipedia/commons/thumb/1/15/\(name)/500px-\(name)"))

        let saved = expectation(description: "legacy item saved")
        writer.context.perform {
            let item = CacheDBWriterHelper.fetchOrCreateCacheItem(with: legacyURL, itemKey: legacyKey, variant: variant, in: self.writer.context)
            item?.isDownloaded = true
            CacheDBWriterHelper.save(moc: self.writer.context) { _ in saved.fulfill() }
        }
        wait(for: [saved], timeout: 5)

        let fileName = try XCTUnwrap(dataStore.session.uniqueFileNameForItemKey(legacyKey, variant: variant))
        let headerFileName = try XCTUnwrap(dataStore.session.uniqueHeaderFileNameForItemKey(legacyKey, variant: variant))
        let fileURL = CacheFileWriterHelper.fileURL(for: fileName)
        let headerFileURL = CacheFileWriterHelper.fileURL(for: headerFileName)
        try FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try Data("cached".utf8).write(to: fileURL)
        try NSKeyedArchiver.archivedData(withRootObject: ["Content-Type": "image/jpeg"], requiringSecureCoding: false).write(to: headerFileURL)
        filesToRemove.append(contentsOf: [fileURL, headerFileURL])

        // The gallery builds its URL from the image info, which names the upload host.
        let galleryURL = try XCTUnwrap(URL(string: "https://upload.wikimedia.org/wikipedia/commons/thumb/1/15/\(name)/1280px-\(name)"))
        let response = dataStore.session.cachedResponseForURL(galleryURL, type: .image)

        XCTAssertEqual(response.map { String(decoding: $0.data, as: UTF8.self) }, "cached")
    }
}
