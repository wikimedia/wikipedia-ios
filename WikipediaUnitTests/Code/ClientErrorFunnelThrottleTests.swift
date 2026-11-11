import XCTest
@testable import WMF

final class ClientErrorFunnelThrottleTests: XCTestCase {

    private var now: Date!

    override func setUp() {
        super.setUp()
        now = Date(timeIntervalSince1970: 1_756_000_000)
    }

    func testAllowsUpToCapPerKeyPerWindow() {
        var throttle = ClientErrorThrottle()
        for i in 0..<ClientErrorThrottle.maxEventsPerKeyPerWindow {
            XCTAssertTrue(throttle.shouldLog(errorClass: "Session", urlString: "https://en.wikipedia.org/w/api.php", statusCode: 500, now: now), "event \(i) should be admitted")
        }
        XCTAssertFalse(throttle.shouldLog(errorClass: "Session", urlString: "https://en.wikipedia.org/w/api.php", statusCode: 500, now: now))
    }

    func testKeysAreIndependent() {
        var throttle = ClientErrorThrottle()
        for _ in 0..<ClientErrorThrottle.maxEventsPerKeyPerWindow {
            XCTAssertTrue(throttle.shouldLog(errorClass: "Session", urlString: "https://en.wikipedia.org/w/api.php", statusCode: 500, now: now))
        }
        // Different host, error class, or status class each get their own window
        XCTAssertTrue(throttle.shouldLog(errorClass: "Session", urlString: "https://de.wikipedia.org/w/api.php", statusCode: 500, now: now))
        XCTAssertTrue(throttle.shouldLog(errorClass: "WMFBasicService", urlString: "https://en.wikipedia.org/w/api.php", statusCode: 500, now: now))
        XCTAssertTrue(throttle.shouldLog(errorClass: "Session", urlString: "https://en.wikipedia.org/w/api.php", statusCode: 404, now: now))
    }

    func testWindowExpiryResetsTheCount() {
        var throttle = ClientErrorThrottle()
        for _ in 0..<ClientErrorThrottle.maxEventsPerKeyPerWindow {
            XCTAssertTrue(throttle.shouldLog(errorClass: "Session", urlString: "https://en.wikipedia.org/w/api.php", statusCode: 500, now: now))
        }
        XCTAssertFalse(throttle.shouldLog(errorClass: "Session", urlString: "https://en.wikipedia.org/w/api.php", statusCode: 500, now: now))

        let afterWindow = now.addingTimeInterval(ClientErrorThrottle.windowDuration + 1)
        XCTAssertTrue(throttle.shouldLog(errorClass: "Session", urlString: "https://en.wikipedia.org/w/api.php", statusCode: 500, now: afterWindow))
    }

    func testRateLimitResponsesCapAtOnePerHostRegardlessOfErrorClass() {
        var throttle = ClientErrorThrottle()
        XCTAssertTrue(throttle.shouldLog(errorClass: "Session", urlString: "https://en.wikipedia.org/w/api.php", statusCode: 429, now: now))
        XCTAssertFalse(throttle.shouldLog(errorClass: "Session", urlString: "https://en.wikipedia.org/w/api.php", statusCode: 429, now: now))
        XCTAssertFalse(throttle.shouldLog(errorClass: "WMFBasicService", urlString: "https://en.wikipedia.org/w/rest.php", statusCode: 429, now: now))

        // A different host gets its own 429 budget
        XCTAssertTrue(throttle.shouldLog(errorClass: "Session", urlString: "https://commons.wikimedia.org/w/api.php", statusCode: 429, now: now))

        // Non-429 errors from the same host are unaffected by the 429 budget
        XCTAssertTrue(throttle.shouldLog(errorClass: "Session", urlString: "https://en.wikipedia.org/w/api.php", statusCode: 500, now: now))
    }

    func testMissingURLAndStatusStillThrottles() {
        var throttle = ClientErrorThrottle()
        for _ in 0..<ClientErrorThrottle.maxEventsPerKeyPerWindow {
            XCTAssertTrue(throttle.shouldLog(errorClass: nil, urlString: nil, statusCode: nil, now: now))
        }
        XCTAssertFalse(throttle.shouldLog(errorClass: nil, urlString: nil, statusCode: nil, now: now))
    }
}
