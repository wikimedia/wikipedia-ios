@objc public protocol EventLoggingSearchSourceProviding {
    var searchSource: String { get }
}

@objc public protocol EventLoggingEventValuesProviding {
    var eventLoggingCategory: EventLoggingCategory { get }
    var eventLoggingLabel: EventLoggingLabel? { get }
}

public protocol EventLoggingStandardEventProviding {
    var standardEvent: Dictionary<String, Any> { get }
}

public extension EventLoggingStandardEventProviding where Self: EventLoggingFunnel {
    var standardEvent: Dictionary<String, Any> {
        guard let aii = appInstallID, let si = sessionID else {
            return ["event_dt": timestamp]
        }
        return ["app_install_id": aii, "session_id": si, "event_dt": timestamp]
    }
    
    func wholeEvent(with event: Dictionary<AnyHashable, Any>) -> Dictionary<String, Any> {
        guard let event = event as? [String: Any] else {
            assertionFailure("Expected dictionary with keys of type String")
            return [:]
        }
        return standardEvent.merging(event, uniquingKeysWith: { (first, _) in first })
    }
}
