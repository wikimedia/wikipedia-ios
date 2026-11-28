import Foundation

/// URL loading hook installed on fixture-backed URLSessions for app-side
/// `Session` traffic and `WMFBasicService` traffic.
final class TestNetworkFixtureURLProtocol: URLProtocol {
    private static let profilePropertyKey = "WMFTestNetworkFixtureProfile"

    /// Tags a request so this protocol does not intercept unrelated URLSession
    /// traffic in the app process.
    static func requestByAddingProfile(_ profile: TestHTTPClientProfile, to request: URLRequest) -> URLRequest {
        guard let mutableRequest = (request as NSURLRequest).mutableCopy() as? NSMutableURLRequest else {
            return request
        }

        URLProtocol.setProperty(profile.rawValue, forKey: profilePropertyKey, in: mutableRequest)
        return mutableRequest as URLRequest
    }

    static func protocolClassesInstallingFixtureProtocol(in protocolClasses: [AnyClass]?) -> [AnyClass] {
        let existingProtocolClasses = protocolClasses ?? []
        guard !existingProtocolClasses.contains(where: { $0 == TestNetworkFixtureURLProtocol.self }) else {
            return existingProtocolClasses
        }

        return [TestNetworkFixtureURLProtocol.self] + existingProtocolClasses
    }

    override static func canInit(with request: URLRequest) -> Bool {
        guard URLProtocol.property(forKey: profilePropertyKey, in: request) != nil else {
            return false
        }

        return TestNetworkFixtureHTTPClient.canHandle(request)
    }

    override static func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    /// Delivers the synthesized response through the normal URLProtocol client
    /// callbacks, keeping `Session` behavior consistent with real URLSession
    /// loads from the caller's point of view.
    override func startLoading() {
        if TestNetworkFixtureOfflineRules.shared.consumeFailure(for: request) {
            client?.urlProtocol(self, didFailWithError: URLError(.notConnectedToInternet))
            return
        }

        guard let profileValue = URLProtocol.property(forKey: Self.profilePropertyKey, in: request) as? String,
              TestHTTPClientProfile(rawValue: profileValue) == .fixtureStrict,
              let fixtureResponse = TestNetworkFixtureHTTPClient.fixtureResponse(for: request),
              let response = TestNetworkFixtureHTTPClient.httpResponse(for: request, fixtureResponse: fixtureResponse) else {
            client?.urlProtocol(self, didFailWithError: URLError(.badServerResponse))
            return
        }

        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: fixtureResponse.body)
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}

/// Requests that a UI test wants to fail as if the device were offline. The UI-test target sends the
/// rules as base64 JSON through the `-WMFUITestOfflineRequests` launch argument. Each rule uses the
/// matchers of a fixture manifest row, plus `count`: the number of matching requests that fail
/// before the fixture answers again. Without `count`, every matching request fails.
final class TestNetworkFixtureOfflineRules: @unchecked Sendable {
    static let launchArgumentKey = "WMFUITestOfflineRequests"
    static let shared = TestNetworkFixtureOfflineRules(userDefaults: .standard)

    private struct Rule: Decodable {
        let matcher: TestNetworkFixture
        var remainingFailures: Int?

        private enum CodingKeys: String, CodingKey {
            case count
        }

        init(from decoder: Decoder) throws {
            matcher = try TestNetworkFixture(from: decoder)
            remainingFailures = try decoder.container(keyedBy: CodingKeys.self).decodeIfPresent(Int.self, forKey: .count)
        }
    }

    /// URLProtocol instances start on URLSession worker queues.
    private let lock = NSLock()
    private var rules: [Rule]

    init(userDefaults: UserDefaults) {
        guard let base64 = userDefaults.string(forKey: Self.launchArgumentKey),
              let data = Data(base64Encoded: base64),
              let rules = try? JSONDecoder().decode([Rule].self, from: data) else {
            self.rules = []
            return
        }
        self.rules = rules
    }

    /// True when the request must fail. A rule with a count spends one failure on each match.
    func consumeFailure(for request: URLRequest) -> Bool {
        lock.lock()
        defer {
            lock.unlock()
        }

        guard let index = rules.firstIndex(where: { $0.matcher.matches(request) && ($0.remainingFailures ?? 1) > 0 }) else {
            return false
        }

        if let remainingFailures = rules[index].remainingFailures {
            rules[index].remainingFailures = remainingFailures - 1
        }
        return true
    }
}
