import Foundation
import WMF
import WMFData

// Stateless — no stored properties, and EventPlatformClient.submit handles its
// own synchronization — so it is safe to use from any thread.
@objc(WMFClientErrorFunnel) public final class ClientErrorFunnel: NSObject, @unchecked Sendable {

    @objc public static let shared = ClientErrorFunnel()

    private struct Event: EventInterface {
        static let schema: EventPlatformClient.Schema = .clientError
        let message: String?
        let errorClass: String?
        let errorContext: String?
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
            errorContext: nil,
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

        let http = Event.Http(method: info.method, statusCode: info.statusCode)
        let event = Event(
            message: "HTTP \(info.statusCode)",
            errorClass: info.source,
            errorContext: nil,
            stackTrace: nil,
            url: info.url,
            http: http
        )
        EventPlatformClient.shared.submit(stream: .clientError, event: event, needsMinimal: true)
    }
}
