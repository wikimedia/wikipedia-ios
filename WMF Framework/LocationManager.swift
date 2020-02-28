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
    public private(set) lazy var location: CLLocation? = self.locationManager.location

    /// The latest known heading.
    public private(set) lazy var heading: CLHeading? = self.locationManager.heading

    /// Returns `true` when the location and heading monitoring is active.
    public private(set) var isUpdating = false

    /// Set the delegate if you want to receive location and heading updates.
    public var delegate: LocationManagerDelegate?

    /// Returns the current locationManager permission state.
    public var autorizationStatus: CLAuthorizationStatus { type(of: locationManager).authorizationStatus() }

    /// Starts monitoring location and heading updates.
    public func startMonitoringLocation() {
        guard autorizationStatus != .notDetermined else {
            authorize(succcess: startMonitoringLocation)
            return
        }

        guard autorizationStatus.isAuthorized else {
            // Start monitoring location in case the authorization status ever changes to authorized.
            authorizedCompletion = startMonitoringLocation
            return
        }

        locationManager.startUpdatingLocation()
        startUpdatingHeading()
        isUpdating = true
    }

    /// Stops monitoring location and heading updates.
    public func stopMonitoringLocation() {
        locationManager.stopUpdatingLocation()
        stopUpdatingHeading()
        isUpdating = false
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
    }

    // MARK: - Private

    private let locationManager: CLLocationManager
    private let device: UIDevice

    // MARK: - Authorization

    /// The completion closure invoked when `authorizationStatus` changes to `authorizedAlways`
    /// or `authorizedWhenInUse`.
    private var authorizedCompletion: (() -> Void)?

    private func authorize(succcess: (() -> Void)? = nil) {
        authorizedCompletion = succcess
        locationManager.requestWhenInUseAuthorization()
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
        delegate?.locationManager(self, didUpdate: location)
    }

    public func locationManager(_ manager: CLLocationManager, didUpdateHeading heading: CLHeading) {
        guard isUpdating else { return }

        self.heading = heading
        delegate?.locationManager(self, didUpdate: heading)
    }

    public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        guard isUpdating else { return }

        #if targetEnvironment(simulator)
        let nsError = error as NSError
        guard !(nsError.domain == kCLErrorDomain && nsError.code == CLError.locationUnknown.rawValue) else {
            return
        }
        #endif

        delegate?.locationManager(self, didReceive: error)
    }

    public func locationManager(
        _ manager: CLLocationManager,
        didChangeAuthorization status: CLAuthorizationStatus
    ) {
        delegate?.locationManager(self, didUpdateAuthorized: status.isAuthorized)

        if status.isAuthorized {
            authorizedCompletion?()
            authorizedCompletion = nil
        }
    }
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
