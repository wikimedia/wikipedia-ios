import Foundation
import WMF
import WMFData
import WMFComponents

// Stateless — no stored properties, and EventPlatformClient.submit handles its
// own synchronization — so it is safe to use from any thread.
@objc(WMFClientErrorFunnel) public final class ClientErrorFunnel: NSObject, @unchecked Sendable {

    @objc public static let shared = ClientErrorFunnel()

    // The schema rejects unknown top-level fields (additionalProperties: false),
    // so the app install ID travels inside error_context, the schema's
    // designated field for arbitrary extra data.
    private static var appInstallIDContext: [String: String]? {
        let appInstallID: String? = try? WMFDataEnvironment.current.crossProcessUserDefaultsStore?.load(key: WMFUserDefaultsKey.appInstallID.rawValue)

        guard let appInstallID else {
            return nil
        }

        return ["app_install_id": appInstallID]
    }

    private struct Event: EventInterface {
        static let schema: EventPlatformClient.Schema = .clientError
        let message: String?
        let errorClass: String?
        let errorContext: [String: String]?
        let stackTrace: String?
        let url: String?
        let http: Http?

        struct Http: Codable {
            let method: String?
            let statusCode: Int

            enum CodingKeys: String, CodingKey {
                case method
                case statusCode = "status_code"
            }
        }

        enum CodingKeys: String, CodingKey {
            case message = "message"
            case errorClass = "error_class"
            case errorContext = "error_context"
            case stackTrace = "stack_trace"
            case url = "url"
            case http = "http"
        }
    }

    func logEvent(message: String?) {
        let event: ClientErrorFunnel.Event = ClientErrorFunnel.Event(
            message: message,
            errorClass: nil,
            errorContext: Self.appInstallIDContext,
            stackTrace: nil,
            url: nil,
            http: nil
        )

        EventPlatformClient.shared.submit(stream: .clientError, event: event, needsMinimal: true)
    }

    public func logHTTPError(info: WMFHTTPErrorInfo) {
        // Never log errors from the event intake itself: that would emit a new event
        // to the same failing endpoint, creating a feedback loop. Intake requests
        // currently bypass the hooks that call this method; this guard makes sure
        // the loop can't be closed by accident later.
        if let url = info.url, url.contains("intake-analytics") || url.contains("intake-logging") {
            return
        }

        // Every HTTP error in the app funnels through here - WMFData's basic service, Session and
        // SessionDelegate all call this method - so this is the one place that sees a 429 no matter
        // which layer made the request.
        RateLimitToastPresenter.shared.handleHTTPError(statusCode: info.statusCode, url: info.url)

        let http = Event.Http(method: info.method, statusCode: info.statusCode)
        let event = Event(
            message: "HTTP \(info.statusCode)",
            errorClass: info.source,
            errorContext: Self.appInstallIDContext,
            stackTrace: nil,
            url: info.url,
            http: http
        )
        EventPlatformClient.shared.submit(stream: .clientError, event: event, needsMinimal: true)
    }
}

// MARK: - Rate limiting

/// Surfaces a toast when the app starts receiving HTTP 429s from any endpoint, so rate limiting is
/// visible instead of showing up as content that silently fails to load.
///
/// Rate limits arrive in bursts, so toasts are throttled to one per `cooldown`, and each toast
/// reports how many 429s were seen since the last one.
@MainActor
final class RateLimitToastPresenter {

    static let shared = RateLimitToastPresenter()

    /// Minimum time between rate limit toasts.
    private static let cooldown: TimeInterval = 30

    private static let toastDuration: TimeInterval = 5

    private var lastToastDate: Date?
    private var countSinceLastToast = 0

    private init() {}

    /// Called for every HTTP error the app observes. Ignores everything but 429.
    nonisolated func handleHTTPError(statusCode: Int, url: String?) {
        guard statusCode == 429 else { return }

        Task { @MainActor in
            self.showToastIfNeeded(url: url)
        }
    }

    private func showToastIfNeeded(url: String?) {
        countSinceLastToast += 1

        if let lastToastDate,
           Date().timeIntervalSince(lastToastDate) < Self.cooldown {
            return
        }

        let count = countSinceLastToast
        lastToastDate = Date()
        countSinceLastToast = 0

        let title = count > 1
            ? "Rate limited: \(count) requests got HTTP 429"
            : "Rate limited: a request got HTTP 429"

        let config = WMFToastConfig(
            title: title,
            subtitle: Self.endpointDescription(for: url),
            icon: WMFSFSymbolIcon.for(symbol: .exclamationMarkTriangleFill),
            duration: Self.toastDuration
        )

        WMFToastPresenter.shared.show(config)
    }

    /// Host plus path, so the toast names the endpoint without dumping a full query string.
    private static func endpointDescription(for url: String?) -> String? {
        guard let url,
              let components = URLComponents(string: url) else {
            return nil
        }

        guard let host = components.host else {
            return components.path.isEmpty ? nil : components.path
        }

        return host + components.path
    }
}
