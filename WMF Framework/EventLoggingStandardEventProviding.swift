public typealias EventLoggingCategory = String
public typealias EventLoggingLabel = String

@objc public protocol EventLoggingEventValuesProviding {
    var eventLoggingCategory: EventLoggingCategory { get }
    var eventLoggingLabel: EventLoggingLabel? { get }
}

public protocol EventLoggingStandardEventProviding {
    var standardEvent: Dictionary<String, Any> { get }
}

public extension EventLoggingStandardEventProviding where Self: EventLoggingFunnel {
    var standardEvent: Dictionary<String, Any> {
        let appInstallID = wmf_appInstallID()
        let timestamp = DateFormatter.wmf_iso8601Localized().string(from: Date())
        let sessionID = wmf_sessionID()
        return ["app_install_id": appInstallID, "session_id": sessionID, "event_dt": timestamp];
    }
    
    func wholeEvent(with event: Dictionary<AnyHashable, Any>) -> Dictionary<String, Any> {
        guard let event = event as? [String: Any] else {
            assertionFailure("Expected dictionary with keys of type String")
            return [:]
        }
        return standardEvent.merging(event, uniquingKeysWith: { (first, _) in first })
    }
}
