import XCTest
import CoreData
@testable import Wikipedia
@testable import WMF

/// Covers the reading list sync behavior after the server answers 429 or 503.
class ReadingListsSyncServerBusyTests: XCTestCase {

    private var dataStore: MWKDataStore!
    private var httpClient: ServerBusyHTTPClient!
    private var session: Session!
    private var readingListsController: ReadingListsController!

    override func setUp(completion: @escaping (Error?) -> Void) {
        MWKDataStore.createTemporaryDataStore(completion: { dataStore in
            self.dataStore = dataStore
            completion(nil)
        })
    }

    override func tearDown() {
        super.tearDown()
        readingListsController = nil
        session = nil
        httpClient = nil
        dataStore.removeFolderAtBasePath()
    }

    private func makeReadingListsController(responder: @escaping ServerBusyHTTPClient.Responder) {
        httpClient = ServerBusyHTTPClient(responder: responder)
        session = Session(configuration: .current, httpClientProvider: ServerBusyHTTPClientProvider(httpClient: httpClient))
        // ArticleFetcher builds summary requests through the permanent cache. Without it no request leaves the session.
        session.permanentCache = dataStore.cacheController
        let apiController = ReadingListsAPIController(session: session, configuration: .current)
        readingListsController = ReadingListsController(dataStore: dataStore, apiController: apiController)
    }

    private func signInPermanentUser() throws {
        let user = WMFCurrentUser(userID: 1, globalUserID: 1, name: "SyncTestUser", groups: [], editCount: 0, isBlocked: false, isIP: false, isTemp: false, registrationDateString: nil)
        let siteURL = try XCTUnwrap(URL(string: "https://en.wikipedia.org"))
        dataStore.authenticationManager.seedUserCacheIfNeeded(user: user, siteURL: siteURL)
        XCTAssertTrue(dataStore.authenticationManager.authStateIsPermanent)
    }

    /// Runs one request through the session so the 429 answer sets the server busy pause.
    private func primeServerBusyPause() throws {
        let url = try XCTUnwrap(URL(string: "https://en.wikipedia.org/api/rest_v1/page/summary/Prime"))
        let done = expectation(description: "priming request completed")
        let task = session.dataTask(with: URLRequest(url: url)) { _, _, _ in
            done.fulfill()
        }
        task?.resume()
        wait(for: [done], timeout: 5)
        XCTAssertNotNil(session.serverBusyPauseUntil)
    }

    private func runSyncOperation(timeout: TimeInterval = 30) -> Error? {
        let operation = ReadingListsSyncOperation(readingListsController: readingListsController)
        let operationFinished = expectation(description: "sync operation finished")
        operation.completionBlock = {
            operationFinished.fulfill()
        }
        OperationQueue().addOperation(operation)
        wait(for: [operationFinished], timeout: timeout)
        return operation.error
    }

    private func summaryBody(for request: URLRequest) -> Data {
        let title = request.url?.lastPathComponent ?? ""
        let json = "{\"title\":\"\(title)\",\"content_urls\":{\"desktop\":{\"page\":\"https://en.wikipedia.org/wiki/\(title)\"}}}"
        return Data(json.utf8)
    }

    private func remoteListsBody() -> Data {
        let now = DateFormatter.wmf_iso8601().string(from: Date())
        let json = """
        {"lists":[
          {"id":1,"name":"default","description":"","created":"\(now)","updated":"\(now)","default":true},
          {"id":2,"name":"Second list","description":"","created":"\(now)","updated":"\(now)","default":false}
        ],"continue-from":"\(now)"}
        """
        return Data(json.utf8)
    }

    private func remoteEntriesPageBody(listID: Int64, page: Int, next: String?) -> Data {
        let now = DateFormatter.wmf_iso8601().string(from: Date())
        let nextField = next.map { ",\"next\":\"\($0)\"" } ?? ""
        let json = """
        {"entries":[{"id":\(listID * 100 + Int64(page)),"project":"https://en.wikipedia.org","title":"Article_\(listID)_\(page)","created":"\(now)","updated":"\(now)","listId":\(listID)}]\(nextField)}
        """
        return Data(json.utf8)
    }

    private static let jsonHeaders = ["Content-Type": "application/json"]
    private static let serverBusyResponse = ServerBusyHTTPClient.ScriptedResponse(statusCode: 429, headers: ["Retry-After": "30"])

    /// Answers a full sync with two remote lists. List 1 has two pages of entries, list 2 has one.
    /// `lists` replaces the answer of the lists request. `listOnePageTwo` replaces the answer of the second page of list 1.
    private func makeFullSyncResponder(lists: ServerBusyHTTPClient.ScriptedResponse? = nil, listOnePageTwo: ServerBusyHTTPClient.ScriptedResponse? = nil) -> ServerBusyHTTPClient.Responder {
        return { request, _ in
            let headers = ReadingListsSyncServerBusyTests.jsonHeaders
            // URL.path drops the trailing slash. The reading list endpoints end with one.
            let path = request.url?.path(percentEncoded: false) ?? ""
            let query = request.url?.query ?? ""
            if path.hasSuffix("/data/lists/") {
                return lists ?? ServerBusyHTTPClient.ScriptedResponse(statusCode: 200, headers: headers, body: self.remoteListsBody())
            }
            if path.hasSuffix("/data/lists/1/entries/") {
                guard query.contains("next=page2") else {
                    return ServerBusyHTTPClient.ScriptedResponse(statusCode: 200, headers: headers, body: self.remoteEntriesPageBody(listID: 1, page: 1, next: "page2"))
                }
                return listOnePageTwo ?? ServerBusyHTTPClient.ScriptedResponse(statusCode: 200, headers: headers, body: self.remoteEntriesPageBody(listID: 1, page: 2, next: nil))
            }
            if path.hasSuffix("/data/lists/2/entries/") {
                return ServerBusyHTTPClient.ScriptedResponse(statusCode: 200, headers: headers, body: self.remoteEntriesPageBody(listID: 2, page: 1, next: nil))
            }
            return ServerBusyHTTPClient.ScriptedResponse(statusCode: 200, headers: headers, body: self.summaryBody(for: request))
        }
    }

    private func startFullSync() throws {
        try signInPermanentUser()
        readingListsController.isSyncRemotelyEnabled = true
        readingListsController.syncState = [.needsSync]
    }

    /// The entries requests in the order the sync sent them, as "<list id>" or "<list id> <next>".
    private func entriesRequestsInOrder() -> [String] {
        return httpClient.requests.compactMap { request in
            guard let url = request.url, url.path(percentEncoded: false).hasSuffix("/entries/") else {
                return nil
            }
            let listID = url.path(percentEncoded: false).components(separatedBy: "/data/lists/").last?.components(separatedBy: "/").first ?? ""
            let queryItems = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems ?? []
            guard let next = queryItems.first(where: { $0.name == "next" })?.value else {
                return listID
            }
            return "\(listID) \(next)"
        }
    }

    private func assertEveryEntriesRequestAsksForTheLargestPage(file: StaticString = #filePath, line: UInt = #line) {
        let pageSize = "\(ReadingListsAPIController.entriesPageSize)"
        for request in httpClient.requests {
            guard let url = request.url, url.path(percentEncoded: false).hasSuffix("/entries/") else {
                continue
            }
            let limit = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems?.first(where: { $0.name == "limit" })?.value
            XCTAssertEqual(limit, pageSize, "Every entries page asks for the largest page size: \(url)", file: file, line: line)
        }
    }

    private func makeRemoteEntries(count: Int, listID: Int64) -> [APIReadingListEntry] {
        let now = DateFormatter.wmf_iso8601().string(from: Date())
        return (1...count).map { index in
            APIReadingListEntry(id: Int64(index), project: "https://en.wikipedia.org", title: "Article_\(index)", created: now, updated: now, listId: listID, deleted: nil)
        }
    }

    private func countArticlesWithSavedDate() throws -> Int {
        let request: NSFetchRequest<WMFArticle> = WMFArticle.fetchRequest()
        request.predicate = NSPredicate(format: "savedDate != NULL")
        return try dataStore.viewContext.count(for: request)
    }

    private func countReadingListEntries() throws -> Int {
        let request: NSFetchRequest<ReadingListEntry> = ReadingListEntry.fetchRequest()
        return try dataStore.viewContext.count(for: request)
    }

    private func countReadingListEntries(listID: Int64) throws -> Int {
        let request: NSFetchRequest<ReadingListEntry> = ReadingListEntry.fetchRequest()
        request.predicate = NSPredicate(format: "list.readingListID == %lld", listID)
        return try dataStore.viewContext.count(for: request)
    }

    // MARK: - Tests

    func testSyncStopsBeforeRemoteRequestsWhileServerIsBusy() throws {
        makeReadingListsController { _, _ in
            ServerBusyHTTPClient.ScriptedResponse(statusCode: 429, headers: ["Retry-After": "30"])
        }
        try primeServerBusyPause()
        try signInPermanentUser()
        readingListsController.isSyncRemotelyEnabled = true
        readingListsController.syncState = [.needsSync]
        let requestCountBeforeSync = httpClient.requests.count

        let error = runSyncOperation()

        guard case .serverBusy(let pauseUntil)? = error as? ReadingListsOperationError else {
            return XCTFail("Expected serverBusy, got \(String(describing: error))")
        }
        XCTAssertGreaterThan(pauseUntil, Date())
        XCTAssertEqual(httpClient.requests.count, requestCountBeforeSync, "The sync must not add requests while the server asks the app to wait")
        XCTAssertTrue(readingListsController.syncState.contains(.needsSync), "The full sync stays pending for the next run")
    }

    func testLocalCreationKeepsTheFetchedBatchAndStopsWhenServerBecomesBusy() throws {
        let batchSize = ReadingListsSyncOperation.summaryFetchBatchSize
        makeReadingListsController { request, requestIndex in
            guard requestIndex < batchSize else {
                return ServerBusyHTTPClient.ScriptedResponse(statusCode: 429, headers: ["Retry-After": "30"])
            }
            return ServerBusyHTTPClient.ScriptedResponse(statusCode: 200, headers: ["Content-Type": "application/json"], body: self.summaryBody(for: request))
        }
        let readingList = try readingListsController.createReadingList(named: "Busy list")
        readingList.readingListID = NSNumber(value: 1)
        let remoteEntries = makeRemoteEntries(count: batchSize * 2 + 5, listID: 1)
        let readingListsByEntryID = Dictionary(uniqueKeysWithValues: remoteEntries.map { ($0.id, readingList) })
        let operation = ReadingListsSyncOperation(readingListsController: readingListsController)

        let result = try operation.locallyCreate(remoteEntries, with: readingListsByEntryID, in: dataStore.viewContext)

        guard case .interruptedByServerBusy(let pauseUntil) = result else {
            return XCTFail("Expected interruptedByServerBusy, got \(result) after \(httpClient.requests.count) requests and \(try countArticlesWithSavedDate()) saved articles")
        }
        XCTAssertGreaterThan(pauseUntil, Date())
        XCTAssertEqual(httpClient.requests.count, batchSize * 2, "The batch that met the 429 completes, the next batch does not start")
        XCTAssertEqual(try countArticlesWithSavedDate(), batchSize, "Only the articles with a fetched summary are saved")
        XCTAssertEqual(try countReadingListEntries(), batchSize, "Only the articles with a fetched summary get an entry")
    }

    func testFullSyncFetchesEntriesOneListAtATimeAndSavesThem() throws {
        makeReadingListsController(responder: makeFullSyncResponder())
        try startFullSync()

        let error = runSyncOperation()

        XCTAssertNil(error, "Expected no error, got \(String(describing: error)) after requests \(httpClient.requests.compactMap { $0.url })")
        XCTAssertFalse(readingListsController.syncState.contains(.needsSync), "The full sync is done")
        XCTAssertTrue(readingListsController.syncState.contains(.needsUpdate), "The next sync only asks for changes")
        XCTAssertEqual(entriesRequestsInOrder(), ["1", "1 page2", "2"], "All pages of list 1 come before list 2")
        assertEveryEntriesRequestAsksForTheLargestPage()
        XCTAssertEqual(try countReadingListEntries(listID: 1), 2, "Both pages of list 1 are saved")
        XCTAssertEqual(try countReadingListEntries(listID: 2), 1, "The entry of list 2 is saved")
        XCTAssertNotNil(dataStore.viewContext.wmf_stringValue(forKey: WMFReadingListUpdateKey), "The sync saves the date the next update starts from")
    }

    func testFullSyncFetchesEntriesOneListAtATimeAndStopsWhenServerBecomesBusy() throws {
        makeReadingListsController(responder: makeFullSyncResponder(listOnePageTwo: ReadingListsSyncServerBusyTests.serverBusyResponse))
        try startFullSync()

        let error = runSyncOperation()

        guard case .serverBusy(let pauseUntil)? = error as? ReadingListsOperationError else {
            return XCTFail("Expected serverBusy, got \(String(describing: error)) after \(httpClient.requests.count) requests")
        }
        XCTAssertGreaterThan(pauseUntil, Date())
        XCTAssertTrue(readingListsController.syncState.contains(.needsSync), "The full sync stays pending for the next run")
        XCTAssertEqual(entriesRequestsInOrder(), ["1", "1 page2"], "Two pages of the first list, no request for the second list")
        assertEveryEntriesRequestAsksForTheLargestPage()
        XCTAssertEqual(try countReadingListEntries(), 0, "Nothing of the interrupted pass is saved")
        XCTAssertNil(dataStore.viewContext.wmf_stringValue(forKey: WMFReadingListUpdateKey), "The update date waits for a complete full sync")
    }

    func testFullSyncSkipsAListWithAnErrorAndContinuesWithTheNext() throws {
        let serverError = ServerBusyHTTPClient.ScriptedResponse(statusCode: 500, headers: [:])
        makeReadingListsController(responder: makeFullSyncResponder(listOnePageTwo: serverError))
        try startFullSync()

        let error = runSyncOperation()

        XCTAssertNil(error, "A 500 on one list does not stop the sync, got \(String(describing: error))")
        XCTAssertFalse(readingListsController.syncState.contains(.needsSync), "The full sync is done")
        XCTAssertEqual(entriesRequestsInOrder(), ["1", "1 page2", "2"], "List 2 is requested after the error on list 1")
        XCTAssertEqual(try countReadingListEntries(listID: 1), 0, "A list with a failed page keeps no entries from this pass")
        XCTAssertEqual(try countReadingListEntries(listID: 2), 1, "The entry of list 2 is saved")
    }

    func testFullSyncStopsWhenTheListsRequestMeetsABusyServer() throws {
        makeReadingListsController(responder: makeFullSyncResponder(lists: ReadingListsSyncServerBusyTests.serverBusyResponse))
        try startFullSync()

        let error = runSyncOperation()

        guard case .serverBusy(let pauseUntil)? = error as? ReadingListsOperationError else {
            return XCTFail("Expected serverBusy, got \(String(describing: error)) after \(httpClient.requests.count) requests")
        }
        XCTAssertGreaterThan(pauseUntil, Date())
        XCTAssertTrue(readingListsController.syncState.contains(.needsSync), "The full sync stays pending for the next run")
        XCTAssertEqual(entriesRequestsInOrder(), [], "No entries request leaves while the server asks the app to wait")
    }
}
