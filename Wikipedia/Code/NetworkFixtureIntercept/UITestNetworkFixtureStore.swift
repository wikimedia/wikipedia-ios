import Foundation

/// Lazily loads bundled UI-test network fixtures and resolves each matching
/// manifest row into response bytes.
final class UITestNetworkFixtureStore: @unchecked Sendable {
    private enum LoadResult {
        case fixtures([UITestNetworkFixture])
        case failure(LoadFailure)
    }

    private enum LoadFailure {
        case missingManifest(String)
        case unreadableManifest(URL, Error)
        case invalidManifest(URL, Error)
    }

    private static let manifestResourceName = "UITestNetworkFixtures.json"

    /// `URLProtocol` can ask for fixtures from URLSession worker queues.
    private let lock = NSLock()
    private var loadResult: LoadResult?

    func response(for request: URLRequest) -> UITestNetworkFixtureResponse? {
        let fixtures: [UITestNetworkFixture]
        switch loadFixtures() {
        case .fixtures(let loadedFixtures):
            fixtures = loadedFixtures
        case .failure(let failure):
            return Self.loadFailureResponse(for: failure)
        }

        guard let fixture = fixtures.first(where: { $0.matches(request) }) else {
            return nil
        }

        guard let body = bodyData(for: fixture) else {
            return Self.missingBodyResponse(for: fixture)
        }

        return UITestNetworkFixtureResponse(
            statusCode: fixture.statusCode ?? 200,
            headers: fixture.headers ?? ["Content-Type": "application/json"],
            body: body
        )
    }

    func reset() {
        lock.lock()
        defer {
            lock.unlock()
        }

        loadResult = nil
    }

    private func loadFixtures() -> LoadResult {
        lock.lock()
        defer {
            lock.unlock()
        }

        if let loadResult {
            return loadResult
        }

        guard let manifestURL = Self.fixtureResourceURL(named: Self.manifestResourceName) else {
            let loadResult = LoadResult.failure(.missingManifest(Self.manifestResourceName))
            self.loadResult = loadResult
            return loadResult
        }

        do {
            let data = try Data(contentsOf: manifestURL)
            let fixtures = try JSONDecoder().decode([UITestNetworkFixture].self, from: data)
            let loadResult = LoadResult.fixtures(fixtures)
            self.loadResult = loadResult
            return loadResult
        } catch let error as DecodingError {
            let loadResult = LoadResult.failure(.invalidManifest(manifestURL, error))
            self.loadResult = loadResult
            return loadResult
        } catch {
            let loadResult = LoadResult.failure(.unreadableManifest(manifestURL, error))
            self.loadResult = loadResult
            return loadResult
        }
    }

    private func bodyData(for fixture: UITestNetworkFixture) -> Data? {
        if let body = fixture.body {
            return Data(body.utf8)
        }

        if let bodyBase64 = fixture.bodyBase64 {
            return Data(base64Encoded: bodyBase64)
        }

        if let bodyResource = fixture.bodyResource,
           let resourceURL = Self.fixtureResourceURL(named: bodyResource) {
            return try? Data(contentsOf: resourceURL)
        }

        return Data()
    }

    /// Unit tests load resources from the test bundle, while app UI tests load
    /// them from the app bundle, so fixture lookup checks both bundle sets.
    private static func fixtureResourceURL(named resourceName: String) -> URL? {
        for bundle in Bundle.allBundles + [Bundle.main] {
            if let url = bundle.url(forResource: resourceName, withExtension: nil, subdirectory: "Fixtures") {
                return url
            }
        }

        return nil
    }

    /// Treat a bad manifest body reference as a fixture error response instead
    /// of crashing the app process under UI test.
    private static func missingBodyResponse(for fixture: UITestNetworkFixture) -> UITestNetworkFixtureResponse {
        let resource = fixture.bodyResource ?? "<missing resource>"
        return UITestNetworkFixtureResponse(
            statusCode: 500,
            headers: ["Content-Type": "application/json"],
            body: jsonBody([
                "error": "UI test network fixture body missing",
                "resource": resource
            ])
        )
    }

    private static func loadFailureResponse(for failure: LoadFailure) -> UITestNetworkFixtureResponse {
        let body: [String: String]
        switch failure {
        case .missingManifest(let resourceName):
            body = [
                "error": "UI test network fixture manifest missing",
                "resource": resourceName
            ]
        case .unreadableManifest(let manifestURL, let error):
            body = [
                "error": "UI test network fixture manifest unreadable",
                "resource": manifestURL.lastPathComponent,
                "reason": error.localizedDescription
            ]
        case .invalidManifest(let manifestURL, let error):
            body = [
                "error": "UI test network fixture manifest invalid",
                "resource": manifestURL.lastPathComponent,
                "reason": error.localizedDescription
            ]
        }

        return UITestNetworkFixtureResponse(
            statusCode: 500,
            headers: ["Content-Type": "application/json"],
            body: jsonBody(body)
        )
    }

    private static func jsonBody(_ dictionary: [String: String]) -> Data {
        (try? JSONSerialization.data(withJSONObject: dictionary, options: [.sortedKeys])) ?? Data("{}".utf8)
    }
}
