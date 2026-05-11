import Foundation
import WMF
import WMFData

@objc(WMFClientErrorFunnel) final class ClientErrorFunnel: NSObject {

    @objc static let shared = ClientErrorFunnel()

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
}
