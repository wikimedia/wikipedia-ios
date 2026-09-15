import Foundation
import OSLog

public struct WMFRiveFailure: Sendable {

    public enum Stage: String, Sendable {
        case worker
        case file
        case binding
    }

    public let animation: WMFRiveAnimation
    public let stage: Stage
    public let reason: String
}

@MainActor
public enum WMFRiveLogger {

    public static var failureHandler: (@MainActor (WMFRiveFailure) -> Void)?

    private static let logger = Logger(subsystem: "org.wikimedia.wikipedia", category: "Rive")

    static func log(_ failure: WMFRiveFailure) {
        logger.error("""
            Rive \(failure.stage.rawValue, privacy: .public) failure for \
            \(failure.animation.resourceName, privacy: .public) \
            artboard=\(failure.animation.artboardName ?? "default", privacy: .public): \
            \(failure.reason, privacy: .public)
            """)
        failureHandler?(failure)
    }
}
