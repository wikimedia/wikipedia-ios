import Foundation

/// Lazily loads bundled test network fixtures and resolves each matching
/// manifest row into response bytes.
final class TestNetworkFixtureStore: @unchecked Sendable {
    private enum ManifestCache {
        case fixtures([TestNetworkFixture])
        case failureResponse(TestNetworkFixtureResponse)
    }

    private static let manifestResourceName = "TestNetworkFixtures.json"

    /// `URLProtocol` can ask for fixtures from URLSession worker queues.
    private let lock = NSLock()
    private var manifestCache: ManifestCache?

    func response(for request: URLRequest) -> TestNetworkFixtureResponse? {
        let fixtures: [TestNetworkFixture]
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

        return TestNetworkFixtureResponse(
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
                let fixtures = try JSONDecoder().decode([TestNetworkFixture].self, from: data)
                manifestCache = .fixtures(fixtures)
            } catch let error as DecodingError {
                manifestCache = .failureResponse(
                    Self.errorResponse(
                        message: "test network fixture manifest invalid",
                        resource: manifestURL.lastPathComponent,
                        reason: error.localizedDescription
                    )
                )
            } catch {
                manifestCache = .failureResponse(
                    Self.errorResponse(
                        message: "test network fixture manifest unreadable",
                        resource: manifestURL.lastPathComponent,
                        reason: error.localizedDescription
                    )
                )
            }
        } else {
            manifestCache = .failureResponse(
                Self.errorResponse(
                    message: "test network fixture manifest missing",
                    resource: Self.manifestResourceName
                )
            )
        }

        self.manifestCache = manifestCache
        return manifestCache
    }

    private func bodyData(for fixture: TestNetworkFixture) -> Data? {
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
        guard !resourceName.isEmpty else {
            return nil
        }

        for bundle in Bundle.allBundles + [Bundle.main] {
            guard let resourceURL = bundle.resourceURL else {
                continue
            }

            let fixtureURL = resourceURL
                .appendingPathComponent("Fixtures")
                .appendingPathComponent(resourceName)
            if FileManager.default.fileExists(atPath: fixtureURL.path) {
                return fixtureURL
            }
        }

        return nil
    }

    /// Treat a bad manifest body reference as a fixture error response instead
    /// of crashing the app process under UI test.
    private static func missingBodyResponse(for fixture: TestNetworkFixture) -> TestNetworkFixtureResponse {
        let resource = fixture.bodyResource ?? "<missing resource>"
        return errorResponse(
            message: "test network fixture body missing",
            resource: resource
        )
    }

    private static func errorResponse(message: String, resource: String, reason: String? = nil) -> TestNetworkFixtureResponse {
        var body = [
            "error": message,
            "resource": resource
        ]

        if let reason {
            body["reason"] = reason
        }

        return TestNetworkFixtureResponse(
            statusCode: 500,
            headers: ["Content-Type": "application/json"],
            body: jsonBody(body)
        )
    }

    private static func jsonBody(_ dictionary: [String: String]) -> Data {
        (try? JSONSerialization.data(withJSONObject: dictionary, options: [.sortedKeys])) ?? Data("{}".utf8)
    }
}
