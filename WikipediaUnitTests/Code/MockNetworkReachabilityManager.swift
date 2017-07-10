import Foundation
import SystemConfiguration


@objc(WMFMockNetworkReachabilityManager)
class MockNetworkReachabilityManager : AFNetworkReachabilityManager {
    
    fileprivate static let _sharedInstance = MockNetworkReachabilityManager()
 
    fileprivate var _networkReachabilityStatus: AFNetworkReachabilityStatus
    override var networkReachabilityStatus: AFNetworkReachabilityStatus {
        get {
            return _networkReachabilityStatus
        }
        set {
            let oldValue = _networkReachabilityStatus
            _networkReachabilityStatus = newValue
            if (oldValue != newValue) {
                if let block = _reachabilityStatusChangeBlock {
                    block(newValue)
                }
            }
        }
    }

    override var isReachableViaWiFi: Bool {
        get {
            return (_networkReachabilityStatus == .reachableViaWiFi)
        }
    }
    
    override var isReachableViaWWAN: Bool {
        get {
            return (_networkReachabilityStatus == .reachableViaWWAN)
        }
    }
    
    override var isReachable: Bool {
        get {
            return isReachableViaWWAN || isReachableViaWiFi
        }
    }

    fileprivate var _reachabilityStatusChangeBlock: ((AFNetworkReachabilityStatus) -> Swift.Void)?
    
    override func startMonitoring() {
        // do nothing
    }
    
    override func stopMonitoring() {
        // do nothing
    }
    
    public init() {
        _networkReachabilityStatus = AFNetworkReachabilityStatus.unknown

        // you _must_ call the designated initializer (eyeroll)
        
        var zeroAddress = sockaddr_in()
        zeroAddress.sin_len = UInt8(MemoryLayout<sockaddr_in>.size)
        zeroAddress.sin_family = sa_family_t(AF_INET)
        
        let defaultRouteReachability = withUnsafePointer(to: &zeroAddress, {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                SCNetworkReachabilityCreateWithAddress(nil, $0)
            }
        })
        
        super.init(reachability: defaultRouteReachability!)
    }
    
    override func setReachabilityStatusChange(_ block: ((AFNetworkReachabilityStatus) -> Swift.Void)?) {
        _reachabilityStatusChangeBlock = block
    }
    
    override class func shared() -> Self {
        return sharedHelper()  // swift is annoying sometimes
    }
    
    private class func sharedHelper<T>() -> T {
         return _sharedInstance as! T
    }
    
    override private init(reachability: SCNetworkReachability) {
        assertionFailure("not implemented")
        _networkReachabilityStatus = AFNetworkReachabilityStatus.unknown
        super.init(reachability: reachability)
    }
    
    override open func localizedNetworkReachabilityStatusString() -> String {
        assertionFailure("not implemented")
        return ""
    }
    
}
