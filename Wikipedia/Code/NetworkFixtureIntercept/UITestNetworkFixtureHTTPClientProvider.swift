import Foundation

/// Provider selected by launch configuration when UI tests should intercept
/// app-process `Session` traffic with bundled fixtures.
final class UITestNetworkFixtureHTTPClientProvider: SessionHTTPClientProvider {
    private let profile: UITestNetworkFixtureInterceptor.Profile

    init(profile: UITestNetworkFixtureInterceptor.Profile) {
        self.profile = profile
    }

    /// Reuses the production session delegate and base configuration so fixture
    /// mode exercises the same delegate callbacks, cache policy, and cookie
    /// behavior as the normal client.
    func httpClient(defaultURLSession: URLSession, sessionDelegate: SessionDelegate) -> SessionHTTPClient {
        UITestNetworkFixtureHTTPClient(profile: profile, defaultURLSession: defaultURLSession, sessionDelegate: sessionDelegate)
    }
}
