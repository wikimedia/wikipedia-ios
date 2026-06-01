import Foundation

/// Provider selected by launch configuration when tests should intercept
/// app-process `Session` traffic with bundled fixtures.
final class TestNetworkFixtureHTTPClientProvider: SessionHTTPClientProvider {
    private let profile: TestHTTPClientProfile

    init(profile: TestHTTPClientProfile) {
        self.profile = profile
    }

    /// Reuses the production session delegate and base configuration so fixture
    /// mode exercises the same delegate callbacks, cache policy, and cookie
    /// behavior as the normal client.
    func httpClient(defaultURLSession: URLSession, sessionDelegate: SessionDelegate) -> SessionHTTPClient {
        TestNetworkFixtureHTTPClient(profile: profile, defaultURLSession: defaultURLSession, sessionDelegate: sessionDelegate)
    }
}
