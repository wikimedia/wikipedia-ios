import Foundation
import WMFData

/// App-side entry point for turning the normal `Session` transport into a
/// fixture-backed transport during UI tests.
public final class UITestNetworkFixtureInterceptor {
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

    @discardableResult
    public static func configureBasicServiceIfNeeded(userDefaults: UserDefaults = .standard, environment: WMFDataEnvironment = WMFDataEnvironment.current) -> Bool {
#if TEST || UITEST
        guard let urlSession = basicServiceURLSession(profileValue: userDefaults.string(forKey: profileKey)) else {
            return false
        }

        environment.basicService = WMFBasicService(urlSession: urlSession)
        return true
#else
        return false
#endif
    }

    static func basicServiceURLSession(profileValue: String?) -> WMFURLSession? {
#if TEST || UITEST
        guard let profileValue,
              let profile = UITestHTTPClientProfile(rawValue: profileValue),
              profile == .fixtureStrict else {
            return nil
        }

        return UITestNetworkFixtureURLSession(profile: profile)
#else
        return nil
#endif
    }
}
