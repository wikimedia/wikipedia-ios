import Foundation

/// App-side entry point for turning the normal `Session` transport into a
/// fixture-backed transport during UI tests.
final class UITestNetworkFixtureInterceptor {
    /// UserDefaults key written from UI-test launch arguments before `Session`
    /// asks `SessionHTTPClientProviderConfiguration` for its provider.
    static let profileKey = "WMFUITestHTTPClientProfile"

    /// Keep these values aligned with `UITestConfiguration.NetworkMode`.
    enum Profile: String {
        case fixtureStrict = "fixture-strict"
    }

    static func httpClientProvider(profileValue: String?) -> (any SessionHTTPClientProvider)? {
#if TEST || UITEST
        guard let profileValue,
              let profile = Profile(rawValue: profileValue) else {
            return nil
        }

        return UITestNetworkFixtureHTTPClientProvider(profile: profile)
#else
        _ = profileValue
        return nil
#endif
    }
}
