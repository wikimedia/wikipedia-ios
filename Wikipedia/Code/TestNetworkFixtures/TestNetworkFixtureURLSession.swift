import Foundation
import WMFData

/// `WMFURLSession` wrapper that routes `WMFBasicService` requests through the
/// same fixture URLProtocol used by the app-side `Session` transport.
final class TestNetworkFixtureURLSession: WMFURLSession {
    private let profile: TestHTTPClientProfile
    private let urlSession: URLSession

    init(profile: TestHTTPClientProfile, defaultURLSession: URLSession = .shared) {
        self.profile = profile
        let fixtureConfiguration = defaultURLSession.configuration
        fixtureConfiguration.protocolClasses = TestNetworkFixtureURLProtocol.protocolClassesInstallingFixtureProtocol(in: fixtureConfiguration.protocolClasses)
        self.urlSession = URLSession(configuration: fixtureConfiguration)
    }

    deinit {
        urlSession.invalidateAndCancel()
    }

    func wmfDataTask(with request: URLRequest, completionHandler: @escaping @Sendable (Data?, URLResponse?, Error?) -> Void) -> WMFURLSessionDataTask {
        urlSession.wmfDataTask(with: fixtureRequest(for: request), completionHandler: completionHandler)
    }

    func clearCachedData() {
        urlSession.clearCachedData()
    }

    private func fixtureRequest(for request: URLRequest) -> URLRequest {
        TestNetworkFixtureURLProtocol.requestByAddingProfile(profile, to: request)
    }
}
