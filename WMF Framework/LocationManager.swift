import UIKit
import CoreLocation

public struct LocationManagerConfiguration {
    let accuracy: CLLocationAccuracy
    let filter: CLLocationDistance
    var activityType: CLActivityType = .fitness
}

extension LocationManagerConfiguration {
    /// A configuration preset for fine location updates.
    public static let fine = LocationManagerConfiguration(
        accuracy: kCLLocationAccuracyBest,
        filter: 1
    )
  
    /// A configuration preset for coarse location updates.
    public static let coarse = LocationManagerConfiguration(
        accuracy: kCLLocationAccuracyKilometer,
        filter: 1000
    )
}

// MARK: - LocationManagerDelegate

public protocol LocationManagerDelegate: class {
    func locationManager(_ locationManager: LocationManager, didUpdate location: CLLocation)
    func locationManager(_ locationManager: LocationManager, didUpdate heading: CLHeading)
    func locationManager(_ locationManager: LocationManager, didReceive error: Error)
    func locationManager(_ locationManager: LocationManager, didUpdateAuthorized authorized: Bool)
}

final public class LocationManager: NSObject {

    /// The latest known location.
    public var location: CLLocation? { fatalError() }

    /// The latest known heading.
    public var heading: CLHeading? { fatalError() }

    /// Returns `true` when the location and heading monitoring is active.
    public private(set) var isUpdating = false

    /// Set the delegate if you want to receive location and heading updates.
    public var delegate: LocationManagerDelegate?

    /// Returns the current locationManager permission state.
    public var autorizationStatus: CLAuthorizationStatus { fatalError() }

    /// Starts monitoring location and heading updates.
    public func startMonitoringLocation() { }

    /// Stops monitoring location and heading updates.
    public func stopMonitoringLocation() { }

    /// Creates a new instance of `LocationManager`.
    ///
    /// - Parameters:
    ///   - locationManager: If needed, provide a custom `CLLocationManager` instance. The default
    ///   value creates a new instance.
    ///   - device: If needed, provide a custom `UIDevice` instance. The default value is `UIDevice.current`.
    ///   - configuration: The configuration used for configuring `CLLocationManager`. The default value
    ///   is the `.fine` preset.
    ///
    public init(
        locationManager: CLLocationManager = .init(),
        device: UIDevice = .current,
        configuration: LocationManagerConfiguration = .fine
    ) { }
}
