import Foundation
import WMFData

/// `WMFURLSession` wrapper that routes `WMFBasicService` requests through the
/// same fixture URLProtocol used by the app-side `Session` transport.
final class UITestNetworkFixtureURLSession: WMFURLSession {
    private let profile: UITestHTTPClientProfile
    private let urlSession: URLSession

    init(profile: UITestHTTPClientProfile, defaultURLSession: URLSession = .shared) {
        self.profile = profile
        let fixtureConfiguration = defaultURLSession.configuration
        fixtureConfiguration.protocolClasses = UITestNetworkFixtureURLProtocol.protocolClassesInstallingFixtureProtocol(in: fixtureConfiguration.protocolClasses)
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
        UITestNetworkFixtureURLProtocol.requestByAddingProfile(profile, to: request)
    }
}
