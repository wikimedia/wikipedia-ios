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
