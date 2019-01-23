import Foundation
import SystemConfiguration

@objc(WMFReachabilityNotifier) public class ReachabilityNotifier: NSObject {
    private let host: String

    private let queue: DispatchQueue
    private let semaphore: DispatchSemaphore = DispatchSemaphore(value: 1)
    
    private let callback: (Bool, SCNetworkReachabilityFlags) -> Void

    private var reachability: SCNetworkReachability?
    private var _flags: SCNetworkReachabilityFlags = [.reachable]
    private var _isReachable: Bool = true
    
    @objc(initWithHost:callback:) public required init(_ host: String, _ callback: @escaping (Bool, SCNetworkReachabilityFlags) -> Void) {
        self.host = host
        self.queue = DispatchQueue(label: "\(host).reachability.\(UUID().uuidString)")
        self.callback = callback
    }
    
    deinit {
        semaphore.wait()
        defer {
            semaphore.signal()
        }
        _stop()
    }
    
    @objc public var flags: SCNetworkReachabilityFlags {
        semaphore.wait()
        defer {
            semaphore.signal()
        }
        return _flags
    }
    
    @objc public var isReachable: Bool {
        semaphore.wait()
        defer {
            semaphore.signal()
        }
        return _isReachable
    }
    
    @objc public func start() {
        semaphore.wait()
        defer {
            semaphore.signal()
        }
        _start()
    }
    
    @objc public func stop() {
        semaphore.wait()
        defer {
            semaphore.signal()
        }
        _stop()
    }
    
    private func _start() {
        guard self.reachability == nil else {
            return
        }
        guard let reachability = SCNetworkReachabilityCreateWithName(nil, self.host) else {
            return
        }
        SCNetworkReachabilitySetDispatchQueue(reachability, self.queue)
        let info = Unmanaged.passUnretained(self).toOpaque()
        var context = SCNetworkReachabilityContext(version: 0, info: info, retain: nil, release: nil, copyDescription: nil)
        SCNetworkReachabilitySetCallback(reachability, { (reachability, flags, info) in
            guard let info = info else {
                return
            }
            let reachabilityNotifier = Unmanaged<ReachabilityNotifier>.fromOpaque(info).takeUnretainedValue()
            reachabilityNotifier.semaphore.wait()
            reachabilityNotifier._flags = flags
            let callback = reachabilityNotifier.callback
            reachabilityNotifier.semaphore.signal()
            callback(flags.contains(.reachable), flags)
        }, &context)
        self.reachability = reachability
    }
    
    private func _stop() {
        guard let reachability = self.reachability else {
            return
        }
        SCNetworkReachabilitySetCallback(reachability, nil, nil)
        SCNetworkReachabilitySetDispatchQueue(reachability, nil)
        self.reachability = nil
    }
}
