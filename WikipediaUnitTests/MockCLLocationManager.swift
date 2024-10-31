import Foundation
import CoreLocation

/// A `CLLocationManager` subclass allowing mocking in tests.
final class MockCLLocationManager: CLLocationManager {

    private var _heading: CLHeading?
    override var heading: CLHeading? { _heading }

    private var _location: CLLocation?
    override var location: CLLocation? { _location }

    override static func locationServicesEnabled() -> Bool { true }

    private var _authorizationStatus: CLAuthorizationStatus = .authorizedAlways
    override var authorizationStatus: CLAuthorizationStatus {
        return _authorizationStatus
    }

    override func startUpdatingLocation() {
        isUpdatingLocation = true
    }

    override func stopUpdatingLocation() {
        isUpdatingLocation = false
    }

    override func startUpdatingHeading() {
        isUpdatingHeading = true
    }

    override func stopUpdatingHeading() {
        isUpdatingHeading = false
    }

    override func requestWhenInUseAuthorization() {
        isRequestedForAuthorization = true
    }

    // Empty overrides preventing the real interaction with the superclass.
    override func requestAlwaysAuthorization() { }
    override func startMonitoringSignificantLocationChanges() { }
    override func stopMonitoringSignificantLocationChanges() { }

    // MARK: - Test properties

    var isUpdatingLocation: Bool = false
    var isUpdatingHeading: Bool = false
    var isRequestedForAuthorization: Bool?

    /// Simulates a new location being emitted. Updates the `location` property
    /// and notifies the delegate.
    ///
    /// - Parameter location: The new location used.
    ///
    func simulateUpdate(location: CLLocation) {
        _location = location
        delegate?.locationManager?(self, didUpdateLocations: [location])
    }


    /// Simulates a new heading being emitted. Updates the `heading` property
    /// and notifies the delegate.
    ///
    /// - Parameter heading: The new heading used.
    ///
    func simulateUpdate(heading: CLHeading) {
        _heading = heading
        delegate?.locationManager?(self, didUpdateHeading: heading)
    }

    /// Simulates the location manager failing with an error. Notifies the delegate with
    /// the provided error.
    ///
    /// - Parameter error: The error used for the delegate callback.
    ///
    func simulate(error: Error) {
        delegate?.locationManager?(self, didFailWithError: error)
    }

    /// Updates the `authorizationStatus` value and notifies the delegate.
    ///
    /// - Important: ⚠️ `authorizationStatus` is a static variable. Calling
    /// the `simulate(authorizationStatus:)` function will change the value for all
    /// instances of `MockCLLocationManager`. The `didChangeAuthorization` delegate
    /// method is called only on the delegate of this instance.
    ///
    /// - Parameter authorizationStatus: The new authorization status.
    ///
    func simulate(authorizationStatus: CLAuthorizationStatus) {
        _authorizationStatus = authorizationStatus
        delegate?.locationManagerDidChangeAuthorization?(self)
    }   
}
