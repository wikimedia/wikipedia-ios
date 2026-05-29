import Foundation

/// Lazily loads bundled UI-test network fixtures and resolves each matching
/// manifest row into response bytes.
final class UITestNetworkFixtureStore: @unchecked Sendable {
    private enum ManifestCache {
        case fixtures([UITestNetworkFixture])
        case failureResponse(UITestNetworkFixtureResponse)
    }

    private static let manifestResourceName = "TestNetworkFixtures.json"

    /// `URLProtocol` can ask for fixtures from URLSession worker queues.
    private let lock = NSLock()
    private var manifestCache: ManifestCache?

    func response(for request: URLRequest) -> UITestNetworkFixtureResponse? {
        let fixtures: [UITestNetworkFixture]
        switch loadManifest() {
        case .fixtures(let loadedFixtures):
            fixtures = loadedFixtures
        case .failureResponse(let response):
            return response
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

        manifestCache = nil
    }

    private func loadManifest() -> ManifestCache {
        lock.lock()
        defer {
            lock.unlock()
        }

        if let manifestCache {
            return manifestCache
        }

        let manifestCache: ManifestCache
        if let manifestURL = Self.fixtureResourceURL(named: Self.manifestResourceName) {
            do {
                let data = try Data(contentsOf: manifestURL)
                let fixtures = try JSONDecoder().decode([UITestNetworkFixture].self, from: data)
                manifestCache = .fixtures(fixtures)
            } catch let error as DecodingError {
                manifestCache = .failureResponse(
                    Self.errorResponse(
                        message: "UI test network fixture manifest invalid",
                        resource: manifestURL.lastPathComponent,
                        reason: error.localizedDescription
                    )
                )
            } catch {
                manifestCache = .failureResponse(
                    Self.errorResponse(
                        message: "UI test network fixture manifest unreadable",
                        resource: manifestURL.lastPathComponent,
                        reason: error.localizedDescription
                    )
                )
            }
        } else {
            manifestCache = .failureResponse(
                Self.errorResponse(
                    message: "UI test network fixture manifest missing",
                    resource: Self.manifestResourceName
                )
            )
        }

        self.manifestCache = manifestCache
        return manifestCache
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
        return errorResponse(
            message: "UI test network fixture body missing",
            resource: resource
        )
    }

    private static func errorResponse(message: String, resource: String, reason: String? = nil) -> UITestNetworkFixtureResponse {
        var body = [
            "error": message,
            "resource": resource
        ]

        if let reason {
            body["reason"] = reason
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
