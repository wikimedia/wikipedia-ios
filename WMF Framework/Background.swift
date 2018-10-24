import Foundation

// Provides abstraction around ProcessInfo.processInfo.performExpiringActivity for classes inside of the WMF.framework that don't have access to UIApplication.shared.beginTask
// Ensures background time is given to complete tasks that lock files

class Background {
    struct ExpiringTaskIdentifier {
        fileprivate let uuid: UUID
        init() {
            uuid = UUID()
        }
    }
    
    struct SynchronousTaskIdentifier {
        fileprivate let activityObject: NSObjectProtocol
        init(_ activityObject: NSObjectProtocol) {
            self.activityObject = activityObject
        }
    }
    
    static let manager = Background()
    
    public func beginTask(_ reason: String = UUID().uuidString) -> SynchronousTaskIdentifier {
        return SynchronousTaskIdentifier(ProcessInfo.processInfo.beginActivity(options: .background, reason: reason))
    }
    
    public func endTask(_ task: SynchronousTaskIdentifier) {
        ProcessInfo.processInfo.endActivity(task.activityObject)
    }
    
    private let queue = DispatchQueue(label: "Background.manager." + UUID().uuidString)
    private var groups: [UUID: DispatchGroup] = [:]
    
    public func beginExpiringTask(withName taskName: String? = nil, expirationHandler handler: (() -> Void)? = nil) -> ExpiringTaskIdentifier {
        let identifier = ExpiringTaskIdentifier()
        let uuid = identifier.uuid
        let group = DispatchGroup()
        group.enter()
        queue.async {
            self.groups[uuid] = group
        }
        DDLogDebug("BTM: began background task \(uuid)")
        ProcessInfo.processInfo.performExpiringActivity(withReason: taskName ?? uuid.uuidString) { (expired) in
            guard !expired else {
                handler?()
                self.endExpiringTask(identifier)
                return
            }
            group.wait() // since performExpiringActivity assumes this is a synchronous task, block until our async task completes as recommended in https://forums.developer.apple.com/thread/105855
            DDLogDebug("BTM: finished background task \(uuid)")
        }
        return identifier
    }
    
    public func endExpiringTask(_ identifier: ExpiringTaskIdentifier) {
        queue.async {
            self.groups[identifier.uuid]?.leave()
            self.groups.removeValue(forKey: identifier.uuid)
        }
    }
    
}
