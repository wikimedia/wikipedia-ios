import Foundation

/// URL loading hook installed only on the fixture-backed URLSession created by
/// `UITestNetworkFixtureHTTPClient`.
final class UITestNetworkFixtureURLProtocol: URLProtocol {
    private static let profilePropertyKey = "WMFUITestNetworkFixtureProfile"

    /// Tags a request so this protocol does not intercept unrelated URLSession
    /// traffic in the app process.
    static func requestByAddingProfile(_ profile: UITestNetworkFixtureInterceptor.Profile, to request: URLRequest) -> URLRequest {
        guard let mutableRequest = (request as NSURLRequest).mutableCopy() as? NSMutableURLRequest else {
            return request
        }

        URLProtocol.setProperty(profile.rawValue, forKey: profilePropertyKey, in: mutableRequest)
        return mutableRequest as URLRequest
    }

    override static func canInit(with request: URLRequest) -> Bool {
        guard URLProtocol.property(forKey: profilePropertyKey, in: request) != nil else {
            return false
        }

        return UITestNetworkFixtureHTTPClient.canHandle(request)
    }

    override static func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    /// Delivers the synthesized response through the normal URLProtocol client
    /// callbacks, keeping `Session` behavior consistent with real URLSession
    /// loads from the caller's point of view.
    override func startLoading() {
        guard let profileValue = URLProtocol.property(forKey: Self.profilePropertyKey, in: request) as? String,
              UITestNetworkFixtureInterceptor.Profile(rawValue: profileValue) != nil,
              let fixtureResponse = UITestNetworkFixtureHTTPClient.fixtureResponse(for: request),
              let response = UITestNetworkFixtureHTTPClient.httpResponse(for: request, fixtureResponse: fixtureResponse) else {
            client?.urlProtocol(self, didFailWithError: URLError(.badServerResponse))
            return
        }

        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: fixtureResponse.body)
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}
