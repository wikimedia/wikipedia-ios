import Foundation

/// `SessionHTTPClient` wrapper that tags requests for fixture interception and
/// delegates the actual task creation back to a URLSession-backed client.
final class TestNetworkFixtureHTTPClient: SessionHTTPClient {
    /// URLProtocol callbacks can arrive on URLSession-controlled queues, so the
    /// fixture manifest is shared through a locked store.
    private static let fixtureStore = TestNetworkFixtureStore()
    private let profile: TestHTTPClientProfile
    private let fixtureURLSession: URLSession
    private let fixtureClient: SessionHTTPClient

    init(profile: TestHTTPClientProfile, defaultURLSession: URLSession, sessionDelegate: SessionDelegate) {
        self.profile = profile
        let fixtureConfiguration = defaultURLSession.configuration
        fixtureConfiguration.protocolClasses = TestNetworkFixtureURLProtocol.protocolClassesInstallingFixtureProtocol(in: fixtureConfiguration.protocolClasses)
        let fixtureURLSession = URLSession(configuration: fixtureConfiguration, delegate: sessionDelegate, delegateQueue: sessionDelegate.delegateQueue)
        self.fixtureURLSession = fixtureURLSession
        self.fixtureClient = URLSessionHTTPClient(urlSession: fixtureURLSession, sessionDelegate: sessionDelegate)
    }

    deinit {
        invalidateAndCancel()
    }

    func dataTask(with request: URLRequest, callback: Session.Callback) -> URLSessionTask {
        fixtureClient.dataTask(with: fixtureRequest(for: request), callback: callback)
    }

    func dataTask(with request: URLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask {
        fixtureClient.dataTask(with: fixtureRequest(for: request), completionHandler: completionHandler)
    }

    func downloadTask(with url: URL, completionHandler: @escaping (URL?, URLResponse?, Error?) -> Void) -> URLSessionDownloadTask {
        downloadTask(with: URLRequest(url: url), completionHandler: completionHandler)
    }

    func downloadTask(with request: URLRequest, completionHandler: @escaping (URL?, URLResponse?, Error?) -> Void) -> URLSessionDownloadTask {
        fixtureClient.downloadTask(with: fixtureRequest(for: request), completionHandler: completionHandler)
    }

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        try await fixtureClient.data(for: fixtureRequest(for: request))
    }

    func invalidateAndCancel() {
        fixtureURLSession.invalidateAndCancel()
    }

    static func resetFixtures() {
        fixtureStore.reset()
    }

    private func fixtureRequest(for request: URLRequest) -> URLRequest {
        TestNetworkFixtureURLProtocol.requestByAddingProfile(profile, to: request)
    }

    /// Returns a manifest-backed response when available
    static func fixtureResponse(for request: URLRequest) -> TestNetworkFixtureResponse? {
        if let fixtureResponse = fixtureStore.response(for: request) {
            return fixtureResponse
        }

        guard canHandle(request) else {
            return nil
        }

        return unhandledResponse(for: request)
    }

    static func canHandle(_ request: URLRequest) -> Bool {
        guard let scheme = request.url?.scheme else {
            return false
        }

        return ["http", "https"].contains(scheme)
    }

    static func httpResponse(for request: URLRequest, fixtureResponse: TestNetworkFixtureResponse) -> HTTPURLResponse? {
        guard let url = request.url else {
            return nil
        }

        return HTTPURLResponse(
            url: url,
            statusCode: fixtureResponse.statusCode,
            httpVersion: nil,
            headerFields: fixtureResponse.headers
        )
    }

    /// The 501 response is intentionally JSON so failing test logs show the
    /// exact request that needs a fixture entry.
    private static func unhandledResponse(for request: URLRequest) -> TestNetworkFixtureResponse {
        let method = request.httpMethod ?? "GET"
        let urlString = request.url?.absoluteString ?? "<missing URL>"
        let body = #"{"error":"No test network fixture registered","request":"\#(method) \#(urlString)"}"#
        return TestNetworkFixtureResponse(
            statusCode: 501,
            headers: ["Content-Type": "application/json"],
            body: Data(body.utf8)
        )
    }
}
