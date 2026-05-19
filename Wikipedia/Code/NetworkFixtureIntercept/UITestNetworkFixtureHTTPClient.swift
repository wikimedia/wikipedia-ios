import Foundation

/// `SessionHTTPClient` wrapper that tags requests for fixture interception and
/// delegates the actual task creation back to a URLSession-backed client.
final class UITestNetworkFixtureHTTPClient: SessionHTTPClient {
    /// URLProtocol callbacks can arrive on URLSession-controlled queues, so the
    /// fixture manifest is shared through a locked store.
    private static let fixtureStore = UITestNetworkFixtureStore()
    private let profile: UITestNetworkFixtureInterceptor.Profile
    private let fixtureURLSession: URLSession
    private let fixtureClient: any SessionHTTPClient

    init(profile: UITestNetworkFixtureInterceptor.Profile, defaultURLSession: URLSession, sessionDelegate: SessionDelegate) {
        self.profile = profile

        let fixtureConfiguration = defaultURLSession.configuration
        fixtureConfiguration.protocolClasses = Self.protocolClassesInstallingFixtureProtocol(in: fixtureConfiguration.protocolClasses)
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

#if TEST || UITEST
    static func resetFixtures() {
        fixtureStore.reset()
    }
#endif

    private func fixtureRequest(for request: URLRequest) -> URLRequest {
        UITestNetworkFixtureURLProtocol.requestByAddingProfile(profile, to: request)
    }

    private static func protocolClassesInstallingFixtureProtocol(in protocolClasses: [AnyClass]?) -> [AnyClass] {
        let existingProtocolClasses = protocolClasses ?? []
        guard !existingProtocolClasses.contains(where: { $0 == UITestNetworkFixtureURLProtocol.self }) else {
            return existingProtocolClasses
        }

        return [UITestNetworkFixtureURLProtocol.self] + existingProtocolClasses
    }

    /// Returns a manifest-backed response when available. Strict fixture mode
    /// fails closed for otherwise valid HTTP(S) requests so missing fixtures are
    /// visible in tests instead of silently leaking to the network.
    static func fixtureResponse(for request: URLRequest) -> UITestNetworkFixtureResponse? {
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

    static func httpResponse(for request: URLRequest, fixtureResponse: UITestNetworkFixtureResponse) -> HTTPURLResponse? {
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

    /// The 501 response is intentionally JSON so failing UI-test logs show the
    /// exact request that needs a fixture entry.
    private static func unhandledResponse(for request: URLRequest) -> UITestNetworkFixtureResponse {
        let method = request.httpMethod ?? "GET"
        let urlString = request.url?.absoluteString ?? "<missing URL>"
        let body = #"{"error":"No UI test network fixture registered","request":"\#(method) \#(urlString)"}"#
        return UITestNetworkFixtureResponse(
            statusCode: 501,
            headers: ["Content-Type": "application/json"],
            body: Data(body.utf8)
        )
    }
}
