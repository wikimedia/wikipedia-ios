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

        enum CodingKeys: String, CodingKey {
            case message = "message"
            case errorClass = "error_class"
            case errorContext = "error_context"
            case stackTrace = "stack_trace"
            case url = "url"
        }
    }

    func logEvent(message: String?) {
        let event: ClientErrorFunnel.Event = ClientErrorFunnel.Event(message: message, errorClass: nil, errorContext: nil, stackTrace: nil, url: nil)
        EventPlatformClient.shared.submit(stream: .clientError, event: event, needsMinimal: true)
    }

    public func logHTTPError(statusCode: Int, url: String?) {
        // Never log errors from the event intake itself: that would emit a new event
        // to the same failing endpoint, creating a feedback loop. Intake requests
        // currently bypass the hooks that call this method; this guard makes sure
        // the loop can't be closed by accident later.
        if let url, url.contains("intake-analytics") || url.contains("intake-logging") {
            return
        }

        let event = Event(message: "HTTP \(statusCode)", errorClass: nil, errorContext: nil, stackTrace: nil, url: url)
        EventPlatformClient.shared.submit(stream: .clientError, event: event, needsMinimal: true)
    }
}
