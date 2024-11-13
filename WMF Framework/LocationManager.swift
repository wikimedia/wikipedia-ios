import UIKit
import CoreLocation
import CocoaLumberjackSwift

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

@objc public protocol LocationManagerDelegate: AnyObject {
    @objc(locationManager:didUpdateLocation:) optional
    func locationManager(_ locationManager: LocationManagerProtocol, didUpdate location: CLLocation)
    @objc(locationManager:didUpdateHeading:) optional
    func locationManager(_ locationManager: LocationManagerProtocol, didUpdate heading: CLHeading)
    @objc(locationManager:didReceiveError:) optional
    func locationManager(_ locationManager: LocationManagerProtocol, didReceive error: Error)
    @objc(locationManager:didUpdateAuthorizedState:) optional
    func locationManager(_ locationManager: LocationManagerProtocol, didUpdateAuthorized authorized: Bool)
}

final public class LocationManager: NSObject {

    /// The latest known location.
    public private(set) lazy var location: CLLocation? = self.locationManager.location

    /// The latest known heading.
    public private(set) lazy var heading: CLHeading? = self.locationManager.heading

    /// Returns `true` when the location and heading monitoring is active.
    public private(set) var isUpdating = false

    /// Set the delegate if you want to receive location and heading updates.
    public weak var delegate: LocationManagerDelegate?

    /// Returns the current locationManager permission state.
    public var authorizationStatus: CLAuthorizationStatus { locationManager.authorizationStatus }

    /// Starts monitoring location and heading updates.
    public func startMonitoringLocation() {
        
        guard isUpdating == false else {
            return
        }
        
        guard authorizationStatus != .notDetermined else {
            authorize(success: startMonitoringLocation)
            DDLogDebug("LocationManager - skip monitoring location because status is \(authorizationStatus.rawValue).")
            return
        }

        guard authorizationStatus.isAuthorized else {
            // Start monitoring location in case the authorization status ever changes to authorized.
            authorizedCompletion = startMonitoringLocation
            return
        }

        locationManager.startUpdatingLocation()
        startUpdatingHeading()
        isUpdating = true
        DDLogDebug("LocationManager - did start updating location & heading.")
    }

    /// Stops monitoring location and heading updates.
    public func stopMonitoringLocation() {
        locationManager.stopUpdatingLocation()
        stopUpdatingHeading()
        isUpdating = false
        DDLogDebug("LocationManager - did stop updating location & heading.")
    }
  
    
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
    ) {
        assert(Thread.isMainThread, "Location managers must be created on the main thread")

        locationManager.distanceFilter = configuration.filter
        locationManager.desiredAccuracy = configuration.accuracy
        locationManager.activityType = configuration.activityType
        self.locationManager = locationManager
        self.device = device
        super.init()
        locationManager.delegate = self
    }

    deinit {
        stopMonitoringLocation()
        locationManager.delegate = nil
    }

    // MARK: - Private

    private let locationManager: CLLocationManager
    private let device: UIDevice

    // MARK: - Authorization

    /// The completion closure invoked when `authorizationStatus` changes to `authorizedAlways`
    /// or `authorizedWhenInUse`.
    private var authorizedCompletion: (() -> Void)?

    private func authorize(success: (() -> Void)? = nil) {
        authorizedCompletion = success
        locationManager.requestWhenInUseAuthorization()
        DDLogDebug("LocationManager - requesting authorization to access location when in use.")
    }

    // MARK: - Heading

    /// The observer token for `UIDevice.orientationDidChangeNotification`.
    private var orientationObserver: NSObjectProtocol?

    private func startUpdatingHeading() {
        guard !isUpdating else { return }
        device.beginGeneratingDeviceOrientationNotifications()
        updateHeadingOrientation()
        locationManager.startUpdatingHeading()

        orientationObserver = NotificationCenter.default.addObserver(
            forName: UIDevice.orientationDidChangeNotification,
            object: nil,
            queue: nil
        ) { [weak self] _ in
            self?.updateHeadingOrientation()
        }
    }

    private func stopUpdatingHeading() {
        guard isUpdating else { return }
        device.endGeneratingDeviceOrientationNotifications()
        locationManager.stopUpdatingHeading()

        if let observer = orientationObserver {
            NotificationCenter.default.removeObserver(observer)
            orientationObserver = nil
        }
    }

    private func updateHeadingOrientation() {
        locationManager.headingOrientation = device.orientation.clOrientation
    }
}

// MARK: - LocationManagerDelegate

extension LocationManager: CLLocationManagerDelegate {

    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard isUpdating, let location = locations.last else { return }

        self.location = location
        delegate?.locationManager?(self, didUpdate: location)
        DDLogDebug("LocationManager - did update location: \(location).")
    }

    public func locationManager(_ manager: CLLocationManager, didUpdateHeading heading: CLHeading) {
        guard isUpdating, heading.headingAccuracy > 0 else { return }

        self.heading = heading
        delegate?.locationManager?(self, didUpdate: heading)
        DDLogDebug("LocationManager - did update heading.")
    }

    public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        guard isUpdating else {
            DDLogDebug("LocationManager - suppressing error received after call to stop monitoring location: \(error)")
            return
        }

        #if targetEnvironment(simulator)
        let nsError = error as NSError
        guard !(nsError.domain == kCLErrorDomain && nsError.code == CLError.locationUnknown.rawValue) else {
            return
        }
        #endif

        delegate?.locationManager?(self, didReceive: error)
        DDLogError("LocationManager - encountered error: \(error).")
    }
    
    public func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        DDLogDebug("LocationManager - did change authorization status \(status.rawValue).")
        delegate?.locationManager?(self, didUpdateAuthorized: status.isAuthorized)

        if status.isAuthorized {
            authorizedCompletion?()
            authorizedCompletion = nil
        }
    }
}

// MARK: LocationManagerProtocol

extension LocationManager: LocationManagerProtocol {
    
    public var isAuthorized: Bool { authorizationStatus.isAuthorized }
}

public extension CLAuthorizationStatus {
    var isAuthorized: Bool {
        self == .authorizedAlways || self == .authorizedWhenInUse
    }
}

private extension UIDeviceOrientation {
    var clOrientation: CLDeviceOrientation {
        switch self {
        case .portrait:
            return .portrait
        case .portraitUpsideDown:
            return .portraitUpsideDown
        case .landscapeLeft:
            return .landscapeLeft
        case .landscapeRight:
            return .landscapeRight
        case .faceUp:
            return .faceUp
        case .faceDown:
            return .faceDown
        default:
            return .unknown
        }
    }
}
