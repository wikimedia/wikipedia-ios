import Foundation

/// A `CLHeading` subclass allowing modification of the `headingAccuracy` value.
final class MockCLHeading: CLHeading {
  
    var _headingAccuracy: CLLocationDirection
    override var headingAccuracy: CLLocationDirection { _headingAccuracy }

    init(headingAccuracy: CLLocationDirection) {
        _headingAccuracy = headingAccuracy
        super.init()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
