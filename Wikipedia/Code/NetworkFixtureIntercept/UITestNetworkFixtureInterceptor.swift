import Foundation

/// App-side entry point for turning the normal `Session` transport into a
/// fixture-backed transport during UI tests.
final class UITestNetworkFixtureInterceptor {
    /// UserDefaults key written from UI-test launch arguments before `Session`
    /// asks `SessionHTTPClientProviderConfiguration` for its provider.
    static let profileKey = "WMFUITestHTTPClientProfile"

    static func httpClientProvider(profileValue: String?) -> SessionHTTPClientProvider? {
#if TEST || UITEST
        guard let profileValue,
              let profile = UITestHTTPClientProfile(rawValue: profileValue),
              profile == .fixtureStrict else {
            return nil
        }

        return UITestNetworkFixtureHTTPClientProvider(profile: profile)
#else
        return nil
#endif
    }
}
