import Foundation
import Testing
@testable import WMF
import WMFData

@Suite(.serialized)
final class TestNetworkFixtureInterceptorTests {

    private let fixture = WMFDataTestFixture()

    init() async {
        await fixture.setUp()
        resetSharedFixtureState()
        await fixture.resetWMFDataTestState()
    }

    @Test
    func fixtureStrictProfileReturnsBundledFixture() async throws {
        let provider = try #require(TestNetworkFixtureInterceptor.httpClientProvider(profileValue: TestHTTPClientProfile.fixtureStrict.rawValue))
        let session = Session(configuration: .current, httpClientProvider: provider)
        let url = try #require(URL(string: "https://en.wikipedia.org/api/rest_v1/page/summary/Dog"))

        let (data, response) = try await session.data(for: url)
        let json = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])

        #expect((response as? HTTPURLResponse)?.statusCode == 200)
        #expect(json["title"] as? String == "Dog")
    }

    @Test
    func fixtureStrictProfileReturnsLocalizedBundledFixture() async throws {
        let provider = try #require(TestNetworkFixtureInterceptor.httpClientProvider(profileValue: TestHTTPClientProfile.fixtureStrict.rawValue))
        let session = Session(configuration: .current, httpClientProvider: provider)
        let url = try #require(URL(string: "https://de.wikipedia.org/api/rest_v1/page/summary/Haushund"))

        let (data, response) = try await session.data(for: url)
        let json = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])

        #expect((response as? HTTPURLResponse)?.statusCode == 200)
        #expect(json["title"] as? String == "Haushund")
    }

    @Test
    func fixtureStrictProfileMatchesPercentEncodedLocalizedPath() async throws {
        let provider = try #require(TestNetworkFixtureInterceptor.httpClientProvider(profileValue: TestHTTPClientProfile.fixtureStrict.rawValue))
        let session = Session(configuration: .current, httpClientProvider: provider)
        let url = try #require(URL(string: "https://he.wikipedia.org/api/rest_v1/page/summary/%D7%9B%D7%9C%D7%91_%D7%94%D7%91%D7%99%D7%AA"))

        let (data, response) = try await session.data(for: url)
        let json = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])

        #expect((response as? HTTPURLResponse)?.statusCode == 200)
        #expect(json["title"] as? String == "כלב הבית")
    }

    @Test
    func fixtureMatchesPathPrefix() async throws {
        let provider = try #require(TestNetworkFixtureInterceptor.httpClientProvider(profileValue: TestHTTPClientProfile.fixtureStrict.rawValue))
        let session = Session(configuration: .current, httpClientProvider: provider)
        let url = try #require(URL(string: "https://en.wikipedia.org/api/rest_v1/feed/featured/2026/05/16"))

        let (data, response) = try await session.data(for: url)
        let json = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])
        let featuredArticle = try #require(json["tfa"] as? [String: Any])

        #expect((response as? HTTPURLResponse)?.statusCode == 200)
        #expect(featuredArticle["title"] as? String == "Dog")
    }

    @Test
    func fixtureMatchesStructuredQueryItems() throws {
        let fixture = queryItemFixture()
        let url = try #require(URL(string: "https://en.wikipedia.org/w/api.php?format=json&titles=Dog&action=query"))
        let request = URLRequest(url: url)

        #expect(fixture.matches(request))
    }

    @Test
    func fixtureQueryItemsRequireExactValue() throws {
        let fixture = queryItemFixture()
        let url = try #require(URL(string: "https://en.wikipedia.org/w/api.php?format=json&titles=Dog&action=querying"))
        let request = URLRequest(url: url)

        #expect(fixture.matches(request) == false)
    }

    @Test
    func fixtureMatchesExactURLIncludingQueryByDefault() throws {
        let fixture = exactURLFixture(ignoreQuery: false)
        let matchingURL = try #require(URL(string: "https://en.wikipedia.org/w/api.php?action=query&titles=Dog"))
        let mismatchedURL = try #require(URL(string: "https://en.wikipedia.org/w/api.php?action=querying&titles=Dog"))

        #expect(fixture.matches(URLRequest(url: matchingURL)))
        #expect(fixture.matches(URLRequest(url: mismatchedURL)) == false)
    }

    @Test
    func fixtureCanIgnoreQueryForExactURLMatcher() throws {
        let fixture = exactURLFixture(ignoreQuery: true)
        let url = try #require(URL(string: "https://en.wikipedia.org/w/api.php?action=querying&titles=Cat"))

        #expect(fixture.matches(URLRequest(url: url)))
    }

    @Test
    func fixtureStrictProfileFailsClosedForUnmatchedRequests() async throws {
        let provider = try #require(TestNetworkFixtureInterceptor.httpClientProvider(profileValue: TestHTTPClientProfile.fixtureStrict.rawValue))
        let session = Session(configuration: .current, httpClientProvider: provider)
        let url = try #require(URL(string: "https://en.wikipedia.org/wiki/NoFixtureRegistered"))

        let (data, response) = try await session.data(for: url)
        let json = try #require(JSONSerialization.jsonObject(with: data) as? [String: String])

        #expect((response as? HTTPURLResponse)?.statusCode == 501)
        #expect(json["error"] == "No test network fixture registered")
        #expect(json["request"] == "GET https://en.wikipedia.org/wiki/NoFixtureRegistered")
    }

    @Test
    func invalidProfileDoesNotCreateFixtureProvider() {
        #expect(TestNetworkFixtureInterceptor.httpClientProvider(profileValue: nil) == nil)
        #expect(TestNetworkFixtureInterceptor.httpClientProvider(profileValue: TestHTTPClientProfile.e2e.rawValue) == nil)
    }

    @Test
    func providerConfigurationUsesDefaultProviderWithoutFixtureProfile() throws {
        let userDefaults = try temporaryUserDefaults()

        let provider = SessionHTTPClientProviderConfiguration.httpClientProvider(userDefaults: userDefaults)

        #expect(provider is URLSessionHTTPClientProvider)
    }

    @Test
    func providerConfigurationUsesFixtureProviderForCallerProvidedProfile() async throws {
        let userDefaults = try temporaryUserDefaults()
        userDefaults.set(TestHTTPClientProfile.fixtureStrict.rawValue, forKey: TestNetworkFixtureInterceptor.profileKey)

        let provider = SessionHTTPClientProviderConfiguration.httpClientProvider(userDefaults: userDefaults)
        let session = Session(configuration: .current, httpClientProvider: provider)
        let url = try #require(URL(string: "https://en.wikipedia.org/wiki/NoFixtureRegistered"))

        let (_, response) = try await session.data(for: url)

        #expect((response as? HTTPURLResponse)?.statusCode == 501)
    }

    @Test
    func fixtureProfileConfiguresWMFBasicServiceTraffic() async throws {
        defer {
            resetSharedFixtureState()
        }
        let userDefaults = try temporaryUserDefaults()
        userDefaults.set(TestHTTPClientProfile.fixtureStrict.rawValue, forKey: TestNetworkFixtureInterceptor.profileKey)

        #expect(TestNetworkFixtureInterceptor.configureBasicServiceIfNeeded(userDefaults: userDefaults))

        let controller = WMFImageDataController(basicService: WMFDataEnvironment.current.basicService)
        let url = try #require(URL(string: "https://en.wikipedia.org/api/rest_v1/page/summary/Dog"))
        let data = try await controller.fetchImageData(url: url)
        let json = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])

        #expect(json["title"] as? String == "Dog")
    }

    @Test
    func e2EProfileDoesNotConfigureWMFBasicServiceTraffic() throws {
        let userDefaults = try temporaryUserDefaults()
        userDefaults.set(TestHTTPClientProfile.e2e.rawValue, forKey: TestNetworkFixtureInterceptor.profileKey)

        #expect(TestNetworkFixtureInterceptor.configureBasicServiceIfNeeded(userDefaults: userDefaults) == false)
    }

    @Test
    func sessionTeardownInvalidatesCurrentHTTPClient() {
        let httpClient = InvalidationTrackingHTTPClient()
        let provider = InvalidationTrackingHTTPClientProvider(httpClient: httpClient)
        let session = Session(configuration: .current, httpClientProvider: provider)

        session.teardown()

        withExtendedLifetime(session) {
            #expect(httpClient.invalidationCount == 1)
        }
    }

    @Test
    func fixtureClientSupportsCallbackDataTask() async throws {
        let provider = try #require(TestNetworkFixtureInterceptor.httpClientProvider(profileValue: TestHTTPClientProfile.fixtureStrict.rawValue))
        let session = Session(configuration: .current, httpClientProvider: provider)
        let url = try #require(URL(string: "https://en.wikipedia.org/api/rest_v1/page/summary/Dog"))
        let request = URLRequest(url: url)

        let result = try await callbackDataTaskResult(session: session, request: request)
        let json = try #require(JSONSerialization.jsonObject(with: result.data) as? [String: Any])

        #expect(result.response?.statusCode == 200)
        #expect(json["title"] as? String == "Dog")
        #expect(result.usedCache == false)
    }

    @Test
    func fixtureClientSupportsDownloadTask() async throws {
        let provider = try #require(TestNetworkFixtureInterceptor.httpClientProvider(profileValue: TestHTTPClientProfile.fixtureStrict.rawValue))
        let session = Session(configuration: .current, httpClientProvider: provider)
        let url = try #require(URL(string: "https://en.wikipedia.org/api/rest_v1/page/summary/Dog"))
        let request = URLRequest(url: url)

        let result = try await downloadTaskResult(session: session, request: request)
        let data = try Data(contentsOf: result.fileURL)
        let json = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])

        #expect(result.response?.statusCode == 200)
        #expect(json["title"] as? String == "Dog")
    }

    private func resetSharedFixtureState() {
        UserDefaults.standard.removeObject(forKey: TestNetworkFixtureInterceptor.profileKey)
        WMFDataEnvironment.current.basicService = WMFBasicService()
        TestNetworkFixtureHTTPClient.resetFixtures()
    }

    private struct CallbackDataTaskResult {
        let response: HTTPURLResponse?
        let data: Data
        let usedCache: Bool
    }

    private struct DownloadTaskResult {
        let response: HTTPURLResponse?
        let fileURL: URL
    }

    private func callbackDataTaskResult(session: Session, request: URLRequest) async throws -> CallbackDataTaskResult {
        try await withCheckedThrowingContinuation { continuation in
            var receivedResponse: URLResponse?
            var receivedData = Data()

            let callback = Session.Callback(
                response: { response in
                    receivedResponse = response
                },
                data: { data in
                    receivedData.append(data)
                },
                success: { usedCache in
                    continuation.resume(returning: CallbackDataTaskResult(response: receivedResponse as? HTTPURLResponse, data: receivedData, usedCache: usedCache))
                },
                failure: { error in
                    continuation.resume(throwing: error)
                },
                cacheFallbackError: nil
            )

            guard let task = session.dataTask(with: request, callback: callback) else {
                continuation.resume(throwing: URLError(.unknown))
                return
            }

            task.resume()
        }
    }

    private func downloadTaskResult(session: Session, request: URLRequest) async throws -> DownloadTaskResult {
        try await withCheckedThrowingContinuation { continuation in
            guard let task = session.downloadTask(with: request, completionHandler: { fileURL, response, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let fileURL else {
                    continuation.resume(throwing: URLError(.badServerResponse))
                    return
                }

                continuation.resume(returning: DownloadTaskResult(response: response as? HTTPURLResponse, fileURL: fileURL))
            }) else {
                continuation.resume(throwing: URLError(.unknown))
                return
            }

            task.resume()
        }
    }

    private func temporaryUserDefaults() throws -> UserDefaults {
        let suiteName = "TestNetworkFixtureInterceptorTests-\(UUID().uuidString)"
        let userDefaults = try #require(UserDefaults(suiteName: suiteName))
        userDefaults.removePersistentDomain(forName: suiteName)
        return userDefaults
    }

    private func queryItemFixture() -> TestNetworkFixture {
        TestNetworkFixture(
            method: "GET",
            url: nil,
            ignoreQuery: nil,
            host: "en.wikipedia.org",
            path: "/w/api.php",
            pathPrefix: nil,
            pathSuffix: nil,
            queryItems: [
                "action": "query",
                "titles": "Dog"
            ],
            statusCode: nil,
            headers: nil,
            body: nil,
            bodyBase64: nil,
            bodyResource: nil
        )
    }

    private func exactURLFixture(ignoreQuery: Bool) -> TestNetworkFixture {
        TestNetworkFixture(
            method: "GET",
            url: "https://en.wikipedia.org/w/api.php?action=query&titles=Dog",
            ignoreQuery: ignoreQuery,
            host: nil,
            path: nil,
            pathPrefix: nil,
            pathSuffix: nil,
            queryItems: nil,
            statusCode: nil,
            headers: nil,
            body: nil,
            bodyBase64: nil,
            bodyResource: nil
        )
    }
}

private final class InvalidationTrackingHTTPClient: SessionHTTPClient {
    private(set) var invalidationCount = 0

    func dataTask(with request: URLRequest, callback: Session.Callback) -> URLSessionTask {
        fatalError("Unused in invalidation test")
    }

    func dataTask(with request: URLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask {
        fatalError("Unused in invalidation test")
    }

    func downloadTask(with url: URL, completionHandler: @escaping (URL?, URLResponse?, Error?) -> Void) -> URLSessionDownloadTask {
        fatalError("Unused in invalidation test")
    }

    func downloadTask(with request: URLRequest, completionHandler: @escaping (URL?, URLResponse?, Error?) -> Void) -> URLSessionDownloadTask {
        fatalError("Unused in invalidation test")
    }

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        throw URLError(.unknown)
    }

    func invalidateAndCancel() {
        invalidationCount += 1
    }
}

private struct InvalidationTrackingHTTPClientProvider: SessionHTTPClientProvider {
    let httpClient: InvalidationTrackingHTTPClient

    func httpClient(defaultURLSession: URLSession, sessionDelegate: SessionDelegate) -> SessionHTTPClient {
        httpClient
    }
}
