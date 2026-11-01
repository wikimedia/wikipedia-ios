import XCTest
@testable import Wikipedia
@testable import WMF

class ArticleCacheDBWriterTests: XCTestCase {

    var dataStore: MWKDataStore!
    var writer: ArticleCacheDBWriter!
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

    private func resourceRequest(_ string: String) throws -> URLRequest {
        let url = try XCTUnwrap(URL(string: string))
        return try XCTUnwrap(writer.articleFetcher.urlRequest(from: url, headers: ["Accept": "*/*"]))
    }

    private func markDownloaded(_ request: URLRequest, writeFile: Bool) throws {
        let itemKey = try XCTUnwrap(writer.fetcher.itemKeyForURLRequest(request))
        let saved = expectation(description: "item saved")
        writer.context.perform {
            let item = CacheDBWriterHelper.fetchOrCreateCacheItem(with: request.url!, itemKey: itemKey, variant: nil, in: self.writer.context)
            item?.isDownloaded = true
            CacheDBWriterHelper.save(moc: self.writer.context) { _ in saved.fulfill() }
        }
        wait(for: [saved], timeout: 5)
        if writeFile {
            let fileName = try XCTUnwrap(writer.fetcher.uniqueFileNameForItemKey(itemKey, variant: nil))
            let fileURL = CacheFileWriterHelper.fileURL(for: fileName)
            try FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
            try Data("cached".utf8).write(to: fileURL)
            filesToRemove.append(fileURL)
        }
    }

    private func needed(_ requests: [URLRequest]) -> [URLRequest] {
        let done = expectation(description: "filtered")
        var result: [URLRequest] = []
        writer.requestsNeedingDownload(from: requests) { needed in
            result = needed
            done.fulfill()
        }
        wait(for: [done], timeout: 5)
        return result
    }

    func testSharedResourceAlreadyOnDiskIsNotDownloadedAgain() throws {
        let mathjax = try resourceRequest("https://meta.wikimedia.org/api/rest_v1/data/javascript/mobile/mathjax-\(UUID().uuidString)")
        let mobileHTML = try resourceRequest("https://en.wikipedia.org/api/rest_v1/page/mobile-html/Villa_Savoye")
        try markDownloaded(mathjax, writeFile: true)

        let result = needed([mathjax, mobileHTML])

        XCTAssertEqual(result.map { $0.url }, [mobileHTML.url], "The resource another article already downloaded stays off the network; the article itself still downloads")
    }

    func testDownloadedItemWithMissingFileIsDownloadedAgain() throws {
        // Unique URL: the permanent cache directory is shared by every test run on this simulator.
        let font = try resourceRequest("https://meta.wikimedia.org/api/rest_v1/data/javascript/mobile/mathjax/fonts/\(UUID().uuidString).js")
        try markDownloaded(font, writeFile: false)

        XCTAssertEqual(needed([font]).count, 1, "A downloaded flag without the file on disk must not skip the download")
    }

    func testUnknownResourceIsDownloaded() throws {
        let css = try resourceRequest("https://en.wikipedia.org/api/rest_v1/data/css/mobile/site-\(UUID().uuidString)")

        XCTAssertEqual(needed([css]).count, 1)
    }
}
