import CoreLocation

// TODO: Remove these helpers after `WMFNearbyContentSource` is refactored to Swift and `LocationManager`
// is used only from Swift. It will also be possible to remove all @objc names from the
// `LocationManagerDelegate` declaration.

@objc public protocol LocationManagerProtocol {
    /// Last know location
    var location: CLLocation? { get }
    /// Last know heading
    var heading: CLHeading? { get }
    /// Return `true` in case when monitoring location, in other case return `false`
    var isUpdating: Bool { get }
    /// Delegate for update location manager
    var delegate: LocationManagerDelegate? { get set }
    /// Get current locationManager permission state
    var autorizationStatus: CLAuthorizationStatus { get }
    /// Return `true` if user is aurthorized or authorized always
    var isAuthorized: Bool { get }

    /// Start monitoring location and heading updates.
    func startMonitoringLocation()
    /// Stop monitoring location and heading updates.
    func stopMonitoringLocation()
}

@objc final class LocationManagerFactory: NSObject {
    @objc static func coarseLocationManager() -> LocationManagerProtocol {
        return LocationManager(configuration: .coarse)
    }
}

extension LocationManager: LocationManagerProtocol {
    public var isAuthorized: Bool { autorizationStatus.isAuthorized }
}
