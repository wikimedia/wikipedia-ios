
import Foundation

@objc final class LocationManagerFactory: NSObject {
    @objc static func coarseLocationManager() -> LocationManagerProtocol {
        return LocationManager(configuration: .coarse)
    }
}
