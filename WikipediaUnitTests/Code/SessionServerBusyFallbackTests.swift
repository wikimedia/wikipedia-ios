import XCTest
import WMFData
@testable import Wikipedia
@testable import WMF

/// Replays a fixed HTTP status and headers for requests tagged by `request(_:statusCode:headers:)`.
final class ServerBusyURLProtocol: URLProtocol, @unchecked Sendable {
    private static let statusCodeKey = "ServerBusyURLProtocol.statusCode"
    private static let headersKey = "ServerBusyURLProtocol.headers"

    static var configuration: URLSessionConfiguration {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [ServerBusyURLProtocol.self]
        return configuration
    }

    static func request(_ request: URLRequest, statusCode: Int, headers: [String: String]) -> URLRequest {
        guard let mutableRequest = (request as NSURLRequest).mutableCopy() as? NSMutableURLRequest else {
            preconditionFailure("URLRequest should bridge to NSMutableURLRequest")
        }
        URLProtocol.setProperty(statusCode, forKey: statusCodeKey, in: mutableRequest)
        URLProtocol.setProperty(headers, forKey: headersKey, in: mutableRequest)
        return mutableRequest as URLRequest
    }

    override static func canInit(with request: URLRequest) -> Bool {
        URLProtocol.property(forKey: statusCodeKey, in: request) != nil
    }

    override static func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        guard let url = request.url,
              let statusCode = URLProtocol.property(forKey: Self.statusCodeKey, in: request) as? Int,
              let response = HTTPURLResponse(url: url, statusCode: statusCode, httpVersion: nil, headerFields: URLProtocol.property(forKey: Self.headersKey, in: request) as? [String: String]) else {
            client?.urlProtocol(self, didFailWithError: URLError(.badURL))
            return
        }
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: Data("busy".utf8))
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {
    }
}

/// `SessionHTTPClient` that answers every completion-handler data task with the same status.
final class ServerBusyHTTPClient: SessionHTTPClient {
    let statusCode: Int
    let headers: [String: String]
    private lazy var urlSession = URLSession(configuration: ServerBusyURLProtocol.configuration)

    init(statusCode: Int, headers: [String: String]) {
        self.statusCode = statusCode
        self.headers = headers
    }

    func dataTask(with request: URLRequest, callback: Session.Callback) -> URLSessionTask {
        fatalError("Callback data tasks are not used by these tests")
    }

    func dataTask(with request: URLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask {
        urlSession.dataTask(with: ServerBusyURLProtocol.request(request, statusCode: statusCode, headers: headers), completionHandler: completionHandler)
    }

    func downloadTask(with url: URL, completionHandler: @escaping (URL?, URLResponse?, Error?) -> Void) -> URLSessionDownloadTask {
        fatalError("Download tasks are not used by these tests")
    }

    func downloadTask(with request: URLRequest, completionHandler: @escaping (URL?, URLResponse?, Error?) -> Void) -> URLSessionDownloadTask {
        fatalError("Download tasks are not used by these tests")
    }

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        throw URLError(.unsupportedURL)
    }
}

struct ServerBusyHTTPClientProvider: SessionHTTPClientProvider {
    let httpClient: ServerBusyHTTPClient

    func httpClient(defaultURLSession: URLSession, sessionDelegate: SessionDelegate) -> SessionHTTPClient {
        httpClient
    }
}

class SessionServerBusyFallbackTests: XCTestCase {

    var dataStore: MWKDataStore!

    override func setUp(completion: @escaping (Error?) -> Void) {
        MWKDataStore.createTemporaryDataStore(completion: { dataStore in
            self.dataStore = dataStore
            completion(nil)
        })
    }

    override func tearDown() {
        super.tearDown()
        dataStore.removeFolderAtBasePath()
    }

    private func makeSession(statusCode: Int, headers: [String: String]) throws -> (Session, PermanentCacheController) {
        let client = ServerBusyHTTPClient(statusCode: statusCode, headers: headers)
        let session = Session(configuration: .current, httpClientProvider: ServerBusyHTTPClientProvider(httpClient: client))
        let permanentCache = try XCTUnwrap(dataStore.cacheController)
        session.permanentCache = permanentCache
        return (session, permanentCache)
    }

    private func seedCache(_ permanentCache: PermanentCacheController, request: URLRequest, data: Data) throws {
        let url = try XCTUnwrap(request.url)
        let okResponse = try XCTUnwrap(HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: ["Content-Type": "text/html"]))
        let seeded = expectation(description: "cache seeded")
        permanentCache.urlCache.cacheResponse(httpUrlResponse: okResponse, content: .data(data), urlRequest: request, success: {
            seeded.fulfill()
        }, failure: { error in
            XCTFail("Could not seed the permanent cache: \(error)")
            seeded.fulfill()
        })
        wait(for: [seeded], timeout: 5)
    }

    private func perform(_ request: URLRequest, on session: Session) -> (Data?, URLResponse?, Error?) {
        let done = expectation(description: "request completed")
        var result: (Data?, URLResponse?, Error?) = (nil, nil, nil)
        let task = session.dataTask(with: request) { data, response, error in
            result = (data, response, error)
            done.fulfill()
        }
        task?.resume()
        wait(for: [done], timeout: 5)
        return result
    }

    func testServerBusyFallsBackToPermanentCacheAndNotesThePause() throws {
        let (session, permanentCache) = try makeSession(statusCode: 429, headers: ["Retry-After": "30"])
        let url = try XCTUnwrap(URL(string: "https://en.wikipedia.org/api/rest_v1/page/mobile-html/Foo"))
        let request = permanentCache.urlCache.urlRequestFromURL(url, type: .article)
        let cachedData = Data("<html>cached</html>".utf8)
        try seedCache(permanentCache, request: request, data: cachedData)

        let (data, response, error) = perform(request, on: session)

        XCTAssertEqual(data, cachedData, "A 429 should be answered from the permanent cache")
        XCTAssertEqual((response as? HTTPURLResponse)?.statusCode, 200)
        XCTAssertNil(error)
        let pauseUntil = try XCTUnwrap(session.serverBusyPauseUntil, "The session should remember the Retry-After pause")
        XCTAssertEqual(pauseUntil.timeIntervalSinceNow, 30, accuracy: 2)
    }

    func testServerBusyWithoutCacheReturnsTheResponse() throws {
        let (session, permanentCache) = try makeSession(statusCode: 503, headers: [:])
        let url = try XCTUnwrap(URL(string: "https://en.wikipedia.org/api/rest_v1/page/mobile-html/NotCached"))
        let request = permanentCache.urlCache.urlRequestFromURL(url, type: .article)

        let (data, response, error) = perform(request, on: session)

        XCTAssertEqual((response as? HTTPURLResponse)?.statusCode, 503, "With nothing cached the caller sees the real status")
        XCTAssertEqual(data, Data("busy".utf8))
        XCTAssertNil(error)
        let pauseUntil = try XCTUnwrap(session.serverBusyPauseUntil)
        XCTAssertEqual(pauseUntil.timeIntervalSinceNow, Session.defaultServerBusyPause, accuracy: 2)
    }

    func testSuccessDoesNotNoteAPause() throws {
        let (session, permanentCache) = try makeSession(statusCode: 200, headers: [:])
        let url = try XCTUnwrap(URL(string: "https://en.wikipedia.org/api/rest_v1/page/mobile-html/Fine"))
        let request = permanentCache.urlCache.urlRequestFromURL(url, type: .article)
        var reported: [WMFHTTPErrorInfo] = []
        session.reportHTTPError = { reported.append($0) }

        _ = perform(request, on: session)

        XCTAssertNil(session.serverBusyPauseUntil)
        XCTAssertTrue(reported.isEmpty, "A 200 is not an error")
    }

    func testServerBusyIsReportedWithEndpointEvenWhenServedFromCache() throws {
        let (session, permanentCache) = try makeSession(statusCode: 429, headers: ["Retry-After": "30"])
        let url = try XCTUnwrap(URL(string: "https://en.wikipedia.org/api/rest_v1/page/mobile-html/Foo"))
        let request = permanentCache.urlCache.urlRequestFromURL(url, type: .article)
        try seedCache(permanentCache, request: request, data: Data("cached".utf8))
        var reported: [WMFHTTPErrorInfo] = []
        session.reportHTTPError = { reported.append($0) }

        _ = perform(request, on: session)

        XCTAssertEqual(reported.count, 1)
        XCTAssertEqual(reported.first?.statusCode, 429)
        XCTAssertEqual(reported.first?.method, "GET")
        XCTAssertEqual(reported.first?.url, url.absoluteString, "The data lake needs the endpoint to group 429s")
        XCTAssertEqual(reported.first?.source, "Session.dataTask")
        XCTAssertEqual(reported.first?.retryAfter, 30)
        XCTAssertEqual(reported.first?.servedFromCache, true)

        let context = ClientErrorFunnel.httpErrorContext(for: try XCTUnwrap(reported.first))
        XCTAssertEqual(context?["retry_after"], "30")
        XCTAssertEqual(context?["served_from_cache"], "true")
    }

    func testDecodableTaskReportsAServerBusyResponseOnce() throws {
        let (session, permanentCache) = try makeSession(statusCode: 429, headers: ["Retry-After": "5"])
        let url = try XCTUnwrap(URL(string: "https://en.wikipedia.org/api/rest_v1/page/media-list/Once"))
        let request = permanentCache.urlCache.urlRequestFromURL(url, type: .article)
        var reported: [WMFHTTPErrorInfo] = []
        session.reportHTTPError = { reported.append($0) }

        let done = expectation(description: "decodable task completed")
        var receivedError: Error?
        let task: URLSessionDataTask? = session.jsonDecodableTask(with: request) { (result: [String: String]?, _, error) in
            receivedError = error
            done.fulfill()
        }
        XCTAssertNotNil(task)
        wait(for: [done], timeout: 5)

        XCTAssertEqual(reported.count, 1, "The wrapper and handleResponse must not both report the same response")
        XCTAssertTrue((receivedError as? RequestError)?.isServerBusy == true)
    }

    func testDecodableTaskByURLReportsOnce() throws {
        let (session, _) = try makeSession(statusCode: 429, headers: ["Retry-After": "9"])
        let url = try XCTUnwrap(URL(string: "https://en.wikipedia.org/api/rest_v1/feed/featured/2026/10/20"))
        var reported: [WMFHTTPErrorInfo] = []
        session.reportHTTPError = { reported.append($0) }

        let done = expectation(description: "decodable task by url completed")
        var receivedError: Error?
        let task: URLSessionDataTask? = session.jsonDecodableTask(with: url) { (result: [String: String]?, _, error) in
            receivedError = error
            done.fulfill()
        }
        XCTAssertNotNil(task)
        wait(for: [done], timeout: 5)

        XCTAssertEqual(reported.count, 1, "jsonDecodableTask(with url:) goes to the transport directly; dataTask(with url:) must report once")
        XCTAssertEqual(reported.first?.retryAfter, 9)
        XCTAssertEqual(reported.first?.url, url.absoluteString)
        XCTAssertTrue((receivedError as? RequestError)?.isServerBusy == true)
    }

    func testDictionaryTaskTurnsANonJSONBusyBodyIntoAServerBusyError() throws {
        let (session, _) = try makeSession(statusCode: 429, headers: ["Retry-After": "7"])
        let url = try XCTUnwrap(URL(string: "https://en.wikipedia.org/w/api.php?action=query&meta=tokens&type=login&format=json"))
        var reported: [WMFHTTPErrorInfo] = []
        session.reportHTTPError = { reported.append($0) }

        let done = expectation(description: "dictionary task completed")
        var receivedError: Error?
        session.getJSONDictionary(from: url) { _, _, error in
            receivedError = error
            done.fulfill()
        }
        wait(for: [done], timeout: 5)

        let requestError = try XCTUnwrap(receivedError as? RequestError, "The body is not JSON; the caller must still see the 429, not a parse error")
        XCTAssertTrue(requestError.isServerBusy)
        XCTAssertEqual(requestError.retryAfter, 7)
        XCTAssertTrue(WMFAuthenticationManager.isTransientError(requestError), "Login must treat it as transient and keep the session")
        XCTAssertEqual(reported.count, 1)
        XCTAssertEqual(reported.first?.source, "Session")
        XCTAssertEqual(try XCTUnwrap(session.serverBusyPauseUntil).timeIntervalSinceNow, 7, accuracy: 2)
    }

    func testDelegatePathNotesThePauseAndReportsOnce() throws {
        let delegate = SessionDelegate()
        var pauses: [TimeInterval?] = []
        var reported: [WMFHTTPErrorInfo] = []
        delegate.onServerBusy = { pauses.append($0) }
        delegate.reportHTTPError = { reported.append($0) }

        let url = try XCTUnwrap(URL(string: "https://en.wikipedia.org/api/rest_v1/page/mobile-html/Delegate"))
        let task = URLSession.shared.dataTask(with: URLRequest(url: url))
        delegate.callbacks[task.taskIdentifier] = Session.Callback(response: nil, data: nil, success: { _ in }, failure: { _ in }, cacheFallbackError: nil)
        let busy = try XCTUnwrap(HTTPURLResponse(url: url, statusCode: 429, httpVersion: nil, headerFields: ["Retry-After": "30"]))

        delegate.urlSession(URLSession.shared, dataTask: task, didReceive: busy) { _ in }

        XCTAssertEqual(pauses.count, 1)
        XCTAssertEqual(pauses.first ?? nil, 30)
        XCTAssertEqual(reported.count, 1)
        XCTAssertEqual(reported.first?.source, "SessionDelegate")
        XCTAssertEqual(reported.first?.servedFromCache, false)
    }

    func testServerBusyWithoutCacheIsReportedAsNotServedFromCache() throws {
        let (session, permanentCache) = try makeSession(statusCode: 503, headers: [:])
        let url = try XCTUnwrap(URL(string: "https://en.wikipedia.org/api/rest_v1/page/mobile-html/NotCached2"))
        let request = permanentCache.urlCache.urlRequestFromURL(url, type: .article)
        var reported: [WMFHTTPErrorInfo] = []
        session.reportHTTPError = { reported.append($0) }

        _ = perform(request, on: session)

        XCTAssertEqual(reported.first?.statusCode, 503)
        XCTAssertNil(reported.first?.retryAfter)
        XCTAssertEqual(reported.first?.servedFromCache, false)
        XCTAssertNil(ClientErrorFunnel.httpErrorContext(for: try XCTUnwrap(reported.first))?["served_from_cache"])
    }
}
