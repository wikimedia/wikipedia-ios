import Foundation
import WMFData

/// App-side entry point for turning the normal `Session` transport into a
/// fixture-backed transport during tests.
public final class TestNetworkFixtureInterceptor {
    /// UserDefaults key written from test launch arguments before `Session`
    /// asks `SessionHTTPClientProviderConfiguration` for its provider.
    static let profileKey = "WMFTestHTTPClientProfile"

    static func httpClientProvider(profileValue: String?) -> SessionHTTPClientProvider? {
#if TEST || UITEST
        guard let profileValue,
              let profile = TestHTTPClientProfile(rawValue: profileValue),
              profile == .fixtureStrict else {
            return nil
        }

        return TestNetworkFixtureHTTPClientProvider(profile: profile)
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
              let profile = TestHTTPClientProfile(rawValue: profileValue),
              profile == .fixtureStrict else {
            return nil
        }

        return TestNetworkFixtureURLSession(profile: profile)
#else
        return nil
#endif
    }
}
