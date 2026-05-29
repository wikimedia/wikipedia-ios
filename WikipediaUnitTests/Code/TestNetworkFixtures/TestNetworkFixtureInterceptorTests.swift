@testable import WMF
import WMFData
import XCTest

final class TestNetworkFixtureInterceptorTests: XCTestCase {
    override func tearDown() {
        UserDefaults.standard.removeObject(forKey: TestNetworkFixtureInterceptor.profileKey)
        WMFDataEnvironment.current.basicService = WMFBasicService()
        TestNetworkFixtureHTTPClient.resetFixtures()
        super.tearDown()
    }

    func testFixtureStrictProfileReturnsBundledFixture() async throws {
        let provider = try XCTUnwrap(TestNetworkFixtureInterceptor.httpClientProvider(profileValue: TestHTTPClientProfile.fixtureStrict.rawValue))
        let session = Session(configuration: .current, httpClientProvider: provider)
        let url = URL(string: "https://en.wikipedia.org/api/rest_v1/page/summary/Dog")!

        let (data, response) = try await session.data(for: url)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])

        XCTAssertEqual((response as? HTTPURLResponse)?.statusCode, 200)
        XCTAssertEqual(json["title"] as? String, "Dog")
    }

    func testFixtureStrictProfileReturnsLocalizedBundledFixture() async throws {
        let provider = try XCTUnwrap(TestNetworkFixtureInterceptor.httpClientProvider(profileValue: TestHTTPClientProfile.fixtureStrict.rawValue))
        let session = Session(configuration: .current, httpClientProvider: provider)
        let url = URL(string: "https://de.wikipedia.org/api/rest_v1/page/summary/Haushund")!

        let (data, response) = try await session.data(for: url)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])

        XCTAssertEqual((response as? HTTPURLResponse)?.statusCode, 200)
        XCTAssertEqual(json["title"] as? String, "Haushund")
    }

    func testFixtureStrictProfileMatchesPercentEncodedLocalizedPath() async throws {
        let provider = try XCTUnwrap(TestNetworkFixtureInterceptor.httpClientProvider(profileValue: TestHTTPClientProfile.fixtureStrict.rawValue))
        let session = Session(configuration: .current, httpClientProvider: provider)
        let url = URL(string: "https://he.wikipedia.org/api/rest_v1/page/summary/%D7%9B%D7%9C%D7%91_%D7%94%D7%91%D7%99%D7%AA")!

        let (data, response) = try await session.data(for: url)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])

        XCTAssertEqual((response as? HTTPURLResponse)?.statusCode, 200)
        XCTAssertEqual(json["title"] as? String, "כלב הבית")
    }

    func testFixtureMatchesPathPrefix() async throws {
        let provider = try XCTUnwrap(TestNetworkFixtureInterceptor.httpClientProvider(profileValue: TestHTTPClientProfile.fixtureStrict.rawValue))
        let session = Session(configuration: .current, httpClientProvider: provider)
        let url = URL(string: "https://en.wikipedia.org/api/rest_v1/feed/featured/2026/05/16")!

        let (data, response) = try await session.data(for: url)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        let featuredArticle = try XCTUnwrap(json["tfa"] as? [String: Any])

        XCTAssertEqual((response as? HTTPURLResponse)?.statusCode, 200)
        XCTAssertEqual(featuredArticle["title"] as? String, "Dog")
    }

    func testFixtureMatchesStructuredQueryItems() {
        let fixture = queryItemFixture()
        let url = URL(string: "https://en.wikipedia.org/w/api.php?format=json&titles=Dog&action=query")!
        let request = URLRequest(url: url)

        XCTAssertTrue(fixture.matches(request))
    }

    func testFixtureQueryItemsRequireExactValue() {
        let fixture = queryItemFixture()
        let url = URL(string: "https://en.wikipedia.org/w/api.php?format=json&titles=Dog&action=querying")!
        let request = URLRequest(url: url)

        XCTAssertFalse(fixture.matches(request))
    }

    func testFixtureMatchesExactURLIncludingQueryByDefault() {
        let fixture = exactURLFixture(ignoreQuery: false)
        let matchingURL = URL(string: "https://en.wikipedia.org/w/api.php?action=query&titles=Dog")!
        let mismatchedURL = URL(string: "https://en.wikipedia.org/w/api.php?action=querying&titles=Dog")!

        XCTAssertTrue(fixture.matches(URLRequest(url: matchingURL)))
        XCTAssertFalse(fixture.matches(URLRequest(url: mismatchedURL)))
    }

    func testFixtureCanIgnoreQueryForExactURLMatcher() {
        let fixture = exactURLFixture(ignoreQuery: true)
        let url = URL(string: "https://en.wikipedia.org/w/api.php?action=querying&titles=Cat")!

        XCTAssertTrue(fixture.matches(URLRequest(url: url)))
    }

    func testFixtureStrictProfileFailsClosedForUnmatchedRequests() async throws {
        let provider = try XCTUnwrap(TestNetworkFixtureInterceptor.httpClientProvider(profileValue: TestHTTPClientProfile.fixtureStrict.rawValue))
        let session = Session(configuration: .current, httpClientProvider: provider)
        let url = URL(string: "https://en.wikipedia.org/wiki/NoFixtureRegistered")!

        let (data, response) = try await session.data(for: url)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: String])

        XCTAssertEqual((response as? HTTPURLResponse)?.statusCode, 501)
        XCTAssertEqual(json["error"], "No test network fixture registered")
        XCTAssertEqual(json["request"], "GET https://en.wikipedia.org/wiki/NoFixtureRegistered")
    }

    func testInvalidProfileDoesNotCreateFixtureProvider() {
        XCTAssertNil(TestNetworkFixtureInterceptor.httpClientProvider(profileValue: nil))
        XCTAssertNil(TestNetworkFixtureInterceptor.httpClientProvider(profileValue: TestHTTPClientProfile.e2e.rawValue))
    }

    func testProviderConfigurationUsesDefaultProviderWithoutFixtureProfile() throws {
        let userDefaults = try temporaryUserDefaults()

        let provider = SessionHTTPClientProviderConfiguration.httpClientProvider(userDefaults: userDefaults)

        XCTAssertTrue(provider is URLSessionHTTPClientProvider)
    }

    func testProviderConfigurationUsesFixtureProviderForCallerProvidedProfile() async throws {
        let userDefaults = try temporaryUserDefaults()
        userDefaults.set(TestHTTPClientProfile.fixtureStrict.rawValue, forKey: TestNetworkFixtureInterceptor.profileKey)

        let provider = SessionHTTPClientProviderConfiguration.httpClientProvider(userDefaults: userDefaults)
        let session = Session(configuration: .current, httpClientProvider: provider)
        let url = URL(string: "https://en.wikipedia.org/wiki/NoFixtureRegistered")!

        let (_, response) = try await session.data(for: url)

        XCTAssertEqual((response as? HTTPURLResponse)?.statusCode, 501)
    }

    func testFixtureProfileConfiguresWMFBasicServiceTraffic() async throws {
        let userDefaults = try temporaryUserDefaults()
        userDefaults.set(TestHTTPClientProfile.fixtureStrict.rawValue, forKey: TestNetworkFixtureInterceptor.profileKey)

        XCTAssertTrue(TestNetworkFixtureInterceptor.configureBasicServiceIfNeeded(userDefaults: userDefaults))

        let controller = WMFImageDataController(basicService: WMFDataEnvironment.current.basicService)
        let url = try XCTUnwrap(URL(string: "https://en.wikipedia.org/api/rest_v1/page/summary/Dog"))
        let data = try await controller.fetchImageData(url: url)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])

        XCTAssertEqual(json["title"] as? String, "Dog")
    }

    func testE2EProfileDoesNotConfigureWMFBasicServiceTraffic() throws {
        let userDefaults = try temporaryUserDefaults()
        userDefaults.set(TestHTTPClientProfile.e2e.rawValue, forKey: TestNetworkFixtureInterceptor.profileKey)

        XCTAssertFalse(TestNetworkFixtureInterceptor.configureBasicServiceIfNeeded(userDefaults: userDefaults))
    }

    func testSessionTeardownInvalidatesCurrentHTTPClient() {
        let httpClient = InvalidationTrackingHTTPClient()
        let provider = InvalidationTrackingHTTPClientProvider(httpClient: httpClient)
        let session = Session(configuration: .current, httpClientProvider: provider)

        session.teardown()

        withExtendedLifetime(session) {
            XCTAssertEqual(httpClient.invalidationCount, 1)
        }
    }

    func testFixtureClientSupportsCallbackDataTask() async throws {
        let provider = try XCTUnwrap(TestNetworkFixtureInterceptor.httpClientProvider(profileValue: TestHTTPClientProfile.fixtureStrict.rawValue))
        let session = Session(configuration: .current, httpClientProvider: provider)
        let url = URL(string: "https://en.wikipedia.org/api/rest_v1/page/summary/Dog")!
        let request = URLRequest(url: url)
        let expectation = expectation(description: "Fixture callback completes")

        let callback = Session.Callback(
            response: { response in
                XCTAssertEqual((response as? HTTPURLResponse)?.statusCode, 200)
            },
            data: { data in
                let json = try? XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
                XCTAssertEqual(json?["title"] as? String, "Dog")
            },
            success: { usedCache in
                XCTAssertFalse(usedCache)
                expectation.fulfill()
            },
            failure: { error in
                XCTFail("Expected fixture success, got \(error)")
            },
            cacheFallbackError: nil
        )

        let task = try XCTUnwrap(session.dataTask(with: request, callback: callback))
        task.resume()
        await fulfillment(of: [expectation], timeout: 1)
    }

    func testFixtureClientSupportsDownloadTask() async throws {
        let provider = try XCTUnwrap(TestNetworkFixtureInterceptor.httpClientProvider(profileValue: TestHTTPClientProfile.fixtureStrict.rawValue))
        let session = Session(configuration: .current, httpClientProvider: provider)
        let url = URL(string: "https://en.wikipedia.org/api/rest_v1/page/summary/Dog")!
        let request = URLRequest(url: url)
        let expectation = expectation(description: "Fixture download completes")

        let task = try XCTUnwrap(session.downloadTask(with: request) { fileURL, response, error in
            XCTAssertNil(error)
            XCTAssertEqual((response as? HTTPURLResponse)?.statusCode, 200)

            do {
                let fileURL = try XCTUnwrap(fileURL)
                let data = try Data(contentsOf: fileURL)
                let json = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
                XCTAssertEqual(json["title"] as? String, "Dog")
            } catch {
                XCTFail("Expected fixture download body, got \(error)")
            }

            expectation.fulfill()
        })

        task.resume()
        await fulfillment(of: [expectation], timeout: 1)
    }

    private func temporaryUserDefaults() throws -> UserDefaults {
        let suiteName = "TestNetworkFixtureInterceptorTests-\(UUID().uuidString)"
        let userDefaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
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
