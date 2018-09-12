import Foundation

// Provides abstraction around ProcessInfo.processInfo.performExpiringActivity for classes inside of the WMF.framework that don't have access to UIApplication.shared.beginTask
// Ensures background time is given to complete tasks that lock files

class Background {
    struct Identifier {
        fileprivate let uuid: UUID
        init() {
            uuid = UUID()
        }
    }
    
    static let manager = Background()
    
    private let queue = DispatchQueue(label: "Background.manager." + UUID().uuidString)
    
    private var groups: [UUID: DispatchGroup] = [:]
    public func beginTask(withName taskName: String? = nil, expirationHandler handler: (() -> Void)? = nil) -> Identifier {
        let identifier = Identifier()
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
                self.endTask(withIdentifier: identifier)
                return
            }
            group.wait() // since performExpiringActivity assumes this is a synchronous task, block until our async task completes as recommended in https://forums.developer.apple.com/thread/105855
            DDLogDebug("BTM: finished background task \(uuid)")
        }
        return identifier
    }
    
    public func endTask(withIdentifier identifier: Identifier) {
        queue.async {
            self.groups[identifier.uuid]?.leave()
            self.groups.removeValue(forKey: identifier.uuid)
        }
    }
    
}
