import Foundation

class DeviceInfo {
    static let shared = {
        return DeviceInfo()
    }()
    
    lazy var model: String? = {
        var size : Int = 0
        sysctlbyname("hw.machine", nil, &size, nil, 0)
        var machine = [CChar](repeating: 0, count: size)
        sysctlbyname("hw.machine", &machine, &size, nil, 0)
        return String(cString: machine)
    }()
    
    // Only includes iOS 11 compatible older devices
    static let olderDevicePrefixes: Set<String> = [
        "iPad4", // iPad Air
        "iPad5", // iPad Air 2
        "iPhone6", // iPhone 5s
        "iPhone7", // iPhone 6
        "iPod7", // iPod Touch (6th gen)
    ]
    
    lazy var isOlderDevice: Bool = {
        guard let model = model else {
            return true
        }
        guard let substring = model.components(separatedBy: ",").first else {
            return true
        }
        return DeviceInfo.olderDevicePrefixes.contains(substring)
    }()
}
