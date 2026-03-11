import Foundation

public enum DestinationEventService: String {
    case analytics = "eventgate-analytics-external"
    case logging = "eventgate-logging-external"
    case local = "eventgate-logging-local"

    public var baseURI: String {
        switch self {
        case .analytics:
            return "https://intake-analytics.wikimedia.org"
        case .logging:
            return "https://intake-logging.wikimedia.org"
        case .local:
            return "http://localhost:8192"
        }
    }
}
