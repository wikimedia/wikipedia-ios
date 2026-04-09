import Foundation

@objc public final class LocationManagerFactory: NSObject {
    @objc static func coarseLocationManager() -> LocationManagerProtocol {
        if Thread.isMainThread {
            return LocationManager(configuration: .coarse)
        } else {
            return DispatchQueue.main.sync {
                LocationManager(configuration: .coarse)
            }
        }
    }
}
