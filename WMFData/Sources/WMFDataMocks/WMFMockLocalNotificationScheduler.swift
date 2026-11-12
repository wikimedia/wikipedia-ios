import Foundation
import WMFData

#if DEBUG

public actor WMFMockLocalNotificationScheduler: WMFLocalNotificationScheduling {

    public var status: WMFLocalNotificationAuthorizationStatus
    public var addError: Error?
    public private(set) var added: [WMFLocalNotification] = []
    public private(set) var pending: [String] = []
    private var pendingTypes: [String: WMFLocalNotificationType] = [:]
    public private(set) var removed: [String] = []

    public init(status: WMFLocalNotificationAuthorizationStatus = .authorized) {
        self.status = status
    }

    public func setStatus(_ status: WMFLocalNotificationAuthorizationStatus) {
        self.status = status
    }

    public func setAddError(_ error: Error?) {
        self.addError = error
    }

    public func authorizationStatus() async -> WMFLocalNotificationAuthorizationStatus {
        status
    }

    public func add(_ notification: WMFLocalNotification) async throws {
        if let addError {
            throw addError
        }
        added.append(notification)
        pending.append(notification.identifier)
        pendingTypes[notification.identifier] = notification.type
    }

    public func pendingIdentifiers() async -> [String] {
        pending
    }

    public func pendingIdentifiers(type: WMFLocalNotificationType) async -> [String] {
        pending.filter { pendingTypes[$0] == type }
    }

    public func remove(identifiers: [String]) async {
        removed.append(contentsOf: identifiers)
        pending.removeAll { identifiers.contains($0) }
    }
}

#endif
