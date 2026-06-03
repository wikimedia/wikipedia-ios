import Foundation

/// Executes the subset of URLSession work that `Session` needs while keeping
/// request construction, callback handling, and cache behavior owned by `Session`.
protocol SessionHTTPClient {
    func dataTask(with request: URLRequest, callback: Session.Callback) -> URLSessionTask
    func dataTask(with request: URLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask
    func downloadTask(with url: URL, completionHandler: @escaping (URL?, URLResponse?, Error?) -> Void) -> URLSessionDownloadTask
    func downloadTask(with request: URLRequest, completionHandler: @escaping (URL?, URLResponse?, Error?) -> Void) -> URLSessionDownloadTask
    func data(for request: URLRequest) async throws -> (Data, URLResponse)
    func invalidateAndCancel()
}

extension SessionHTTPClient {
    func invalidateAndCancel() {}
}

/// Builds the transport used by a `Session` instance.
///
/// Providers receive the `URLSession` and delegate that `Session` owns so the
/// default implementation can preserve normal delegate callbacks, while test
/// providers can swap in fixture-backed request execution underneath `Session`.
protocol SessionHTTPClientProvider {
    func httpClient(defaultURLSession: URLSession, sessionDelegate: SessionDelegate) -> SessionHTTPClient
}

struct SessionHTTPClientProviderConfiguration {
    /// Selects the app-process network client from launch/defaults state.
    ///
    /// Tests set the fixture profile in `UserDefaults`; production and E2E
    /// runs fall back to the normal URLSession-backed transport.
    static func httpClientProvider(userDefaults: UserDefaults = .standard) -> any SessionHTTPClientProvider {
        if let fixtureProvider = TestNetworkFixtureInterceptor.httpClientProvider(profileValue: userDefaults.string(forKey: TestNetworkFixtureInterceptor.profileKey)) {
            return fixtureProvider
        }

        return URLSessionHTTPClientProvider()
    }
}

/// Production provider that keeps `Session` on its configured URLSession.
struct URLSessionHTTPClientProvider: SessionHTTPClientProvider {
    func httpClient(defaultURLSession: URLSession, sessionDelegate: SessionDelegate) -> SessionHTTPClient {
        URLSessionHTTPClient(urlSession: defaultURLSession, sessionDelegate: sessionDelegate)
    }
}

/// URLSession-backed implementation used outside fixture-backed test runs.
final class URLSessionHTTPClient: SessionHTTPClient {
    private let urlSession: URLSession
    private let sessionDelegate: SessionDelegate

    init(urlSession: URLSession, sessionDelegate: SessionDelegate) {
        self.urlSession = urlSession
        self.sessionDelegate = sessionDelegate
    }

    func dataTask(with request: URLRequest, callback: Session.Callback) -> URLSessionTask {
        let task = urlSession.dataTask(with: request)
        // This preserves `Session`'s existing delegate-driven callback path for
        // callers that stream response/data/success/failure events separately.
        sessionDelegate.addCallback(callback: callback, for: task)
        return task
    }

    func dataTask(with request: URLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask {
        urlSession.dataTask(with: request, completionHandler: completionHandler)
    }

    func downloadTask(with url: URL, completionHandler: @escaping (URL?, URLResponse?, Error?) -> Void) -> URLSessionDownloadTask {
        urlSession.downloadTask(with: url, completionHandler: completionHandler)
    }

    func downloadTask(with request: URLRequest, completionHandler: @escaping (URL?, URLResponse?, Error?) -> Void) -> URLSessionDownloadTask {
        urlSession.downloadTask(with: request, completionHandler: completionHandler)
    }

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        try await urlSession.data(for: request)
    }
}
