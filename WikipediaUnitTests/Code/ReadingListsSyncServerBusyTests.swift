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
}
