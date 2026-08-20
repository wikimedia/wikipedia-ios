import CoreLocation
import XCTest
import WMF
@testable import Wikipedia

/// Tests for the `wikipedia://places?latitude=…&longitude=…` deep link, which lets a calling
/// app open Wikipedia directly on the Places tab centered on a location it supplies.
final class PlacesDeepLinkTests: XCTestCase {

    // MARK: - Helpers

    private func activity(for urlString: String, file: StaticString = #filePath, line: UInt = #line) throws -> NSUserActivity {
        let url = try XCTUnwrap(URL(string: urlString), "Not a valid URL: \(urlString)", file: file, line: line)
        return try XCTUnwrap(NSUserActivity.wmf_activity(forWikipediaScheme: url), "No activity for \(urlString)", file: file, line: line)
    }

    private func coordinate(for urlString: String, file: StaticString = #filePath, line: UInt = #line) throws -> CLLocationCoordinate2D? {
        let activity = try activity(for: urlString, file: file, line: line)
        XCTAssertEqual(activity.wmf_type(), .places, file: file, line: line)
        return WMFAppViewController.requestedPlacesCoordinate(for: activity)
    }

    // MARK: - Coordinates are read from the URL

    func testCoordinateIsParsedFromLongQueryItemNames() throws {
        let coordinate = try XCTUnwrap(coordinate(for: "wikipedia://places?latitude=52.3547498&longitude=4.8339215"))
        XCTAssertEqual(coordinate.latitude, 52.3547498, accuracy: 0.000001)
        XCTAssertEqual(coordinate.longitude, 4.8339215, accuracy: 0.000001)
    }

    func testCoordinateIsParsedFromShortQueryItemNames() throws {
        let coordinate = try XCTUnwrap(coordinate(for: "wikipedia://places?lat=-33.8688&lon=151.2093"))
        XCTAssertEqual(coordinate.latitude, -33.8688, accuracy: 0.000001)
        XCTAssertEqual(coordinate.longitude, 151.2093, accuracy: 0.000001)
    }

    func testQueryItemNamesAreCaseInsensitive() throws {
        let coordinate = try XCTUnwrap(coordinate(for: "wikipedia://places?Lat=51.5&LON=-0.12"))
        XCTAssertEqual(coordinate.latitude, 51.5, accuracy: 0.000001)
        XCTAssertEqual(coordinate.longitude, -0.12, accuracy: 0.000001)
    }

    func testOfficialSchemeIsAlsoSupported() throws {
        let coordinate = try XCTUnwrap(coordinate(for: "wikipedia-official://places?latitude=1&longitude=2"))
        XCTAssertEqual(coordinate.latitude, 1, accuracy: 0.000001)
        XCTAssertEqual(coordinate.longitude, 2, accuracy: 0.000001)
    }

    func testLocationNameIsCarriedInUserInfo() throws {
        let activity = try activity(for: "wikipedia://places?latitude=52.3547&longitude=4.8339&name=Amsterdam")
        XCTAssertEqual(activity.userInfo?[WMFPlacesActivityLocationNameKey] as? String, "Amsterdam")
    }

    func testTitleIsAcceptedAsAnAliasForName() throws {
        let activity = try activity(for: "wikipedia://places?lat=52.3547&lon=4.8339&title=Amsterdam%20Centraal")
        XCTAssertEqual(activity.userInfo?[WMFPlacesActivityLocationNameKey] as? String, "Amsterdam Centraal")
    }

    // MARK: - Fallbacks

    func testPlacesWithoutCoordinatesCarriesNoCoordinate() throws {
        XCTAssertNil(try coordinate(for: "wikipedia://places"))
    }

    func testHalfACoordinateIsIgnored() throws {
        XCTAssertNil(try coordinate(for: "wikipedia://places?latitude=52.3547"))
        XCTAssertNil(try coordinate(for: "wikipedia://places?longitude=4.8339"))
    }

    func testOutOfRangeCoordinatesAreRejected() throws {
        XCTAssertNil(try coordinate(for: "wikipedia://places?latitude=120&longitude=4.8339"))
        XCTAssertNil(try coordinate(for: "wikipedia://places?latitude=52.3547&longitude=200"))
    }

    func testNonNumericCoordinatesAreRejected() throws {
        XCTAssertNil(try coordinate(for: "wikipedia://places?latitude=here&longitude=there"))
    }

    /// Deep link values always use a dot as the decimal separator. A comma must not be silently
    /// reinterpreted, which is what happens when the user's locale is used to parse the value.
    func testCommaDecimalSeparatorIsRejected() throws {
        XCTAssertNil(try coordinate(for: "wikipedia://places?latitude=52,3547&longitude=4,8339"))
    }

    func testArticleDeepLinkStillWorks() throws {
        let activity = try activity(for: "wikipedia://places?WMFArticleURL=https://en.wikipedia.org/wiki/Amsterdam")
        XCTAssertEqual(activity.wmf_type(), .places)
        XCTAssertNil(WMFAppViewController.requestedPlacesCoordinate(for: activity))
        XCTAssertEqual(activity.wmf_linkURL()?.absoluteString, "https://en.wikipedia.org/wiki/Amsterdam")
    }

    func testNonPlacesHostIsUnaffected() throws {
        let activity = try activity(for: "wikipedia://explore")
        XCTAssertNotEqual(activity.wmf_type(), .places)
    }

    // MARK: - URL building

    func testBuiltURLRoundTrips() throws {
        let url = NSUserActivity.wmf_placesURL(withLatitude: 52.3547498, longitude: 4.8339215, name: "Amsterdam")
        let activity = try XCTUnwrap(NSUserActivity.wmf_activity(forWikipediaScheme: url))
        let coordinate = try XCTUnwrap(WMFAppViewController.requestedPlacesCoordinate(for: activity))

        XCTAssertEqual(url.scheme, "wikipedia")
        XCTAssertEqual(url.host, "places")
        XCTAssertEqual(coordinate.latitude, 52.3547498, accuracy: 0.0001)
        XCTAssertEqual(coordinate.longitude, 4.8339215, accuracy: 0.0001)
        XCTAssertEqual(activity.userInfo?[WMFPlacesActivityLocationNameKey] as? String, "Amsterdam")
    }

    func testBuiltURLEscapesTheName() throws {
        let url = NSUserActivity.wmf_placesURL(withLatitude: 0, longitude: 0, name: "Hell's Kitchen & Co")
        let activity = try XCTUnwrap(NSUserActivity.wmf_activity(forWikipediaScheme: url))
        XCTAssertEqual(activity.userInfo?[WMFPlacesActivityLocationNameKey] as? String, "Hell's Kitchen & Co")
    }

    // MARK: - Activity factory

    func testActivityFactoryStoresCoordinate() throws {
        let activity = NSUserActivity.wmf_placesActivity(withLatitude: 10.5, longitude: -20.25, name: nil)
        let coordinate = try XCTUnwrap(WMFAppViewController.requestedPlacesCoordinate(for: activity))
        XCTAssertEqual(coordinate.latitude, 10.5, accuracy: 0.000001)
        XCTAssertEqual(coordinate.longitude, -20.25, accuracy: 0.000001)
        XCTAssertNil(activity.userInfo?[WMFPlacesActivityLocationNameKey])
        XCTAssertEqual(activity.wmf_type(), .places)
    }

    // MARK: - Launch behaviour

    func testAppLaunchesIntoPlacesTab() {
        XCTAssertTrue(WMFAppViewController.launchesIntoPlacesTab, "The app is expected to open on the Places tab.")
    }

    // MARK: - Coordinate description

    func testCoordinateDescriptionUsesThreeDecimals() {
        let description = PlacesViewController.coordinateDescription(for: CLLocationCoordinate2D(latitude: 52.3547498, longitude: 4.8339215))
        XCTAssertTrue(description.contains("52"), "Unexpected description: \(description)")
        XCTAssertTrue(description.contains("4"), "Unexpected description: \(description)")
    }
}
