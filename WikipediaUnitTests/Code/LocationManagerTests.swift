import XCTest
@testable import WMF

final class LocationManagerTests: XCTestCase {

    private var mockCLLocationManager: MockCLLocationManager!
    private var mockDevice: MockUIDevice!
    private var locationManager: LocationManager!
    private var delegate: TestLocationManagerDelegate!

    override func setUp() {
        super.setUp()

        mockCLLocationManager = MockCLLocationManager()
        mockCLLocationManager.simulate(authorizationStatus: .authorizedAlways)

        mockDevice = MockUIDevice(orientation: .unknown)

        locationManager = LocationManager(
            locationManager: mockCLLocationManager,
            device: mockDevice
        )

        delegate = TestLocationManagerDelegate()
        locationManager.delegate = delegate
    }

    // MARK: - LocationManager tests

    func testFineLocationManager() {
        let clLocationManager = CLLocationManager()
        _ = LocationManager(locationManager: clLocationManager, configuration: .fine)
        XCTAssertEqual(clLocationManager.distanceFilter, 1)
        XCTAssertEqual(clLocationManager.desiredAccuracy, kCLLocationAccuracyBest)
        XCTAssertEqual(clLocationManager.activityType, .fitness)
    }

    func testCoarseLocationManager() {
        let clLocationManager = CLLocationManager()
        _ = LocationManager(locationManager: clLocationManager, configuration: .coarse)
        XCTAssertEqual(clLocationManager.distanceFilter, 1000)
        XCTAssertEqual(clLocationManager.desiredAccuracy, kCLLocationAccuracyKilometer)
        XCTAssertEqual(clLocationManager.activityType, .fitness)
    }

    func testStartMonitoring() {
        locationManager.startMonitoringLocation()
        XCTAssertEqual(locationManager.isUpdating, true)
        XCTAssertEqual(mockCLLocationManager.isUpdatingLocation, true)
        XCTAssertEqual(mockCLLocationManager.isUpdatingHeading, true)
    }

    func testStartLocationWithoutPermission() {
        mockCLLocationManager.simulate(authorizationStatus: .denied)
        locationManager.startMonitoringLocation()
        XCTAssertEqual(locationManager.isUpdating, false)
        XCTAssertEqual(mockCLLocationManager.isUpdatingLocation, false)
        XCTAssertEqual(mockCLLocationManager.isUpdatingHeading, false)


        mockCLLocationManager.simulate(authorizationStatus: .restricted)
        locationManager.startMonitoringLocation()
        XCTAssertEqual(locationManager.isUpdating, false)
        XCTAssertEqual(mockCLLocationManager.isUpdatingLocation, false)
        XCTAssertEqual(mockCLLocationManager.isUpdatingHeading, false)
    }

    func testStopMonitoring() {
        locationManager.startMonitoringLocation()
        locationManager.stopMonitoringLocation()
        XCTAssertEqual(locationManager.isUpdating, false)
        XCTAssertEqual(mockCLLocationManager.isUpdatingLocation, false)
        XCTAssertEqual(mockCLLocationManager.isUpdatingHeading, false)
    }

    // MARK: - Authorization

    func testStartMonitoringCalledWhenAuthorizationSuccessfull() {
        mockCLLocationManager.simulate(authorizationStatus: .notDetermined)
        locationManager.startMonitoringLocation()

        XCTAssertEqual(mockCLLocationManager.isRequestedForAuthorization, true)

        XCTAssertEqual(locationManager.isUpdating, false)
        XCTAssertEqual(mockCLLocationManager.isUpdatingLocation, false)
        XCTAssertEqual(mockCLLocationManager.isUpdatingHeading, false)

        // Simulate the user allowing Location Services.
        mockCLLocationManager.simulate(authorizationStatus: .authorizedAlways)

        XCTAssertEqual(locationManager.isUpdating, true)
        XCTAssertEqual(mockCLLocationManager.isUpdatingLocation, true)
        XCTAssertEqual(mockCLLocationManager.isUpdatingHeading, true)
    }

    func testStartMonitoringCalledWhenAuthorizationDeniedAndThenAuthorized() {
        mockCLLocationManager.simulate(authorizationStatus: .denied)
        locationManager.startMonitoringLocation()

        XCTAssertEqual(locationManager.isUpdating, false)
        XCTAssertEqual(mockCLLocationManager.isUpdatingLocation, false)
        XCTAssertEqual(mockCLLocationManager.isUpdatingHeading, false)

        // Simulate the user allowing Location Services.
        mockCLLocationManager.simulate(authorizationStatus: .authorizedAlways)

        XCTAssertEqual(locationManager.isUpdating, true)
        XCTAssertEqual(mockCLLocationManager.isUpdatingLocation, true)
        XCTAssertEqual(mockCLLocationManager.isUpdatingHeading, true)
    }

    func testAuthorizedStatus() {
        // Test authorizedAlways status.
        mockCLLocationManager.simulate(authorizationStatus: .authorizedAlways)
        XCTAssertTrue(locationManager.authorizationStatus.isAuthorized)
        
        // Test when in use status.
        mockCLLocationManager.simulate(authorizationStatus: .authorizedWhenInUse)
        XCTAssertEqual(locationManager.authorizationStatus, .authorizedWhenInUse)
        XCTAssertTrue(locationManager.authorizationStatus.isAuthorized)

        // Test notDetermined status.
        mockCLLocationManager.simulate(authorizationStatus: .notDetermined)
        XCTAssertEqual(locationManager.authorizationStatus, .notDetermined)
        XCTAssertFalse(locationManager.authorizationStatus.isAuthorized)

        // Test denied status.
        mockCLLocationManager.simulate(authorizationStatus: .denied)
        XCTAssertEqual(locationManager.authorizationStatus, .denied)
        XCTAssertFalse(locationManager.authorizationStatus.isAuthorized)

        // Test restricted status.
        mockCLLocationManager.simulate(authorizationStatus: .restricted)
        XCTAssertEqual(locationManager.authorizationStatus, .restricted)
        XCTAssertFalse(locationManager.authorizationStatus.isAuthorized)

    }

    // MARK: - LocationManagerDelegate tests

    func testUpdateLocation() {
        locationManager.startMonitoringLocation()

        let location = CLLocation(latitude: 10, longitude: 20)
        mockCLLocationManager.simulateUpdate(location: location)
        
        XCTAssertEqual(locationManager.location, location)
        XCTAssertEqual(delegate.location, location)
    }

    func testExistingLocationIsUsedWhenAvailable() {
        // When the location has already been fetched, new instances of CLLocationManager contain
        // the last known location in their `location` variable even before `startUpdatingLocation()`
        // is called.

        let location = CLLocation(latitude: 10, longitude: 20)
        mockCLLocationManager.simulateUpdate(location: location)
        let locationManager = LocationManager(locationManager: mockCLLocationManager)
        
        // `locationManager.startMonitoringLocation()` is not called.
      
        XCTAssertEqual(locationManager.location, location)
    }

    func testUpdateHeading() {
        locationManager.startMonitoringLocation()

        let heading = MockCLHeading(headingAccuracy: 10)
        mockCLLocationManager.simulateUpdate(heading: heading)
        
        XCTAssertEqual(locationManager.heading, heading)
        XCTAssertEqual(delegate.heading, heading)
    }

    func testExistingHeadingIsUsedWhenAvailable() {
        // When the heading has already been fetched, new instances of CLLocationManager contain
        // the last known heading in their `heading` variable even before `startUpdatingHeading()`
        // is called.

        let heading = MockCLHeading(headingAccuracy: 10)
        mockCLLocationManager.simulateUpdate(heading: heading)
        let locationManager = LocationManager(locationManager: mockCLLocationManager)
        
        // `locationManager.startMonitoringLocation()` is not called.
        
        XCTAssertEqual(locationManager.heading, heading)
    }

    func testStopUpdating() {
        locationManager.startMonitoringLocation()
        
        // Simulate the values are updated while monitoring.
        let location1 = CLLocation(latitude: 10, longitude: 20)
        mockCLLocationManager.simulateUpdate(location: location1)
        let heading1 = MockCLHeading(headingAccuracy: 10)
        mockCLLocationManager.simulateUpdate(heading: heading1)

        locationManager.stopMonitoringLocation()
        
        // Simulate the values are updated while not monitoring.
        let location2 = CLLocation(latitude: 100, longitude: 200)
        mockCLLocationManager.simulateUpdate(location: location2)
        let heading2 = MockCLHeading(headingAccuracy: 100)
        mockCLLocationManager.simulateUpdate(heading: heading2)

        // Check the values are not updated.
        XCTAssertEqual(locationManager.heading, heading1)
        XCTAssertEqual(delegate.heading, heading1)
        XCTAssertEqual(locationManager.location, location1)
        XCTAssertEqual(delegate.location, location1)

        // Check the error is not propagated when the monitoring is stopped.
        let error = NSError(domain: "org.wikimedia.wikipedia.test", code: -1, userInfo: nil)
        mockCLLocationManager.simulate(error: error)
        XCTAssertNil(delegate.error)
    }

    func testReceivingError() {
        locationManager.startMonitoringLocation()

        let error = NSError(domain: "org.wikimedia.wikipedia.test", code: -1, userInfo: nil)
        mockCLLocationManager.simulate(error: error)
        XCTAssertEqual((delegate.error as NSError?), error)
    }

    func testAuthorizedStateChangesArePropagated() {
        mockCLLocationManager.simulate(authorizationStatus: .denied)
        XCTAssertEqual(delegate.authorized, false)

        mockCLLocationManager.simulate(authorizationStatus: .authorizedAlways)
        XCTAssertEqual(delegate.authorized, true)
    }

    // MARK: - Test heading

    func testDeviceHeadingUpdates() {
        locationManager.startMonitoringLocation()

        mockDevice.simulateUpdate(orientation: .portrait)
        XCTAssertEqual(mockCLLocationManager.headingOrientation, .portrait)

        mockDevice.simulateUpdate(orientation: .landscapeLeft)
        XCTAssertEqual(mockCLLocationManager.headingOrientation, .landscapeLeft)

        // The device orientation updates should not be propagated when the monitoring is stopped.
        locationManager.stopMonitoringLocation()
        mockDevice.simulateUpdate(orientation: .portrait)
        XCTAssertNotEqual(mockCLLocationManager.headingOrientation, .portrait)
    }

    func test_UIDevice_BeingEndGeneratingDeviceOrientation_IsCalled() {
        locationManager.startMonitoringLocation()
        XCTAssertEqual(mockDevice.beginGeneratingDeviceOrientationCount, 1)
        XCTAssertEqual(mockDevice.endGeneratingDeviceOrientationCount, 0)

        // Verify `startMonitoringLocation()` is idempotent.
        locationManager.startMonitoringLocation()
        locationManager.startMonitoringLocation()
        locationManager.startMonitoringLocation()
        XCTAssertEqual(mockDevice.beginGeneratingDeviceOrientationCount, 1)
        XCTAssertEqual(mockDevice.endGeneratingDeviceOrientationCount, 0)

        locationManager.stopMonitoringLocation()
        XCTAssertEqual(mockDevice.beginGeneratingDeviceOrientationCount, 1)
        XCTAssertEqual(mockDevice.endGeneratingDeviceOrientationCount, 1)

        // Verify `stopMonitoringLocation()` is idempotent.
        locationManager.stopMonitoringLocation()
        locationManager.stopMonitoringLocation()
        locationManager.stopMonitoringLocation()
        XCTAssertEqual(mockDevice.beginGeneratingDeviceOrientationCount, 1)
        XCTAssertEqual(mockDevice.endGeneratingDeviceOrientationCount, 1)
    }

    func testMonitoringStopsWhenDeallocated() {
        // Start the monitoring first
        locationManager.startMonitoringLocation()
        XCTAssertEqual(mockCLLocationManager.isUpdatingLocation, true)
        XCTAssertEqual(mockCLLocationManager.isUpdatingHeading, true)
        mockDevice.simulateUpdate(orientation: .portrait)
        XCTAssertEqual(mockCLLocationManager.headingOrientation, .portrait)

        // Deallocate
        locationManager = nil
      
        XCTAssertEqual(mockCLLocationManager.isUpdatingLocation, false)
        XCTAssertEqual(mockCLLocationManager.isUpdatingHeading, false)

        // The device orientation updates should not be propagated
        // when `locationManager` is deallocated.
        mockDevice.simulateUpdate(orientation: .landscapeLeft)
        XCTAssertNotEqual(mockCLLocationManager.headingOrientation, .landscapeLeft)
    }
}

/// A test implementation of `LocationManagerDelegate`.
private final class TestLocationManagerDelegate: LocationManagerDelegate {
    private(set) var heading: CLHeading?
    private(set) var location: CLLocation?
    private(set) var error: Error?
    private(set) var authorized: Bool?

    func locationManager(_ locationManager: LocationManagerProtocol, didReceive error: Error) {
        self.error = error
    }

    func locationManager(_ locationManager: LocationManagerProtocol, didUpdate heading: CLHeading) {
        self.heading = heading
    }

    func locationManager(_ locationManager: LocationManagerProtocol, didUpdate location: CLLocation) {
        self.location = location
    }

    func locationManager(_ locationManager: LocationManagerProtocol, didUpdateAuthorized authorized: Bool) {
        self.authorized = authorized
    }
}
