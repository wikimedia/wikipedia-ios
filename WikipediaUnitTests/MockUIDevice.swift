import UIKit

/// A `UIDevice` subclass allowing mocking in tests.
final class MockUIDevice: UIDevice {

    private var _orientation: UIDeviceOrientation
    override var orientation: UIDeviceOrientation {
        return _orientation
    }

    var beginGeneratingDeviceOrientationCount: Int = 0
    override func beginGeneratingDeviceOrientationNotifications() {
        super.beginGeneratingDeviceOrientationNotifications()
        beginGeneratingDeviceOrientationCount += 1
    }

    var endGeneratingDeviceOrientationCount: Int = 0
    override func endGeneratingDeviceOrientationNotifications() {
        super.endGeneratingDeviceOrientationNotifications()
        endGeneratingDeviceOrientationCount += 1
    }

    init(orientation: UIDeviceOrientation) {
        _orientation = orientation
    }

    /// Simulates changing the device orientation. Updates the `orientation` variable and
    /// posts the `UIDevice.orientationDidChangeNotification` notification.
    ///
    /// - Parameter orientation: The new orientation value.
    ///
    func simulateUpdate(orientation: UIDeviceOrientation) {
        _orientation = orientation

        NotificationCenter.default.post(
            name: UIDevice.orientationDidChangeNotification,
            object: self
        )
    }
}
