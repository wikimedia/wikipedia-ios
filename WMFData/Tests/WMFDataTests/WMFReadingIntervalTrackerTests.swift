import XCTest
@testable import WMFData

final class WMFReadingIntervalTrackerTests: XCTestCase {

    private let start = Date(timeIntervalSince1970: 1_700_000_000)

    private func date(_ secondsFromStart: TimeInterval) -> Date {
        return start.addingTimeInterval(secondsFromStart)
    }

    // MARK: - The regression

    /// The bug: several article view controllers stay alive at once and all observe the app-wide
    /// active notification, so off-screen articles resumed timing and each recorded the full length
    /// of every foreground session.
    func testOffScreenArticleDoesNotAccumulateAcrossForegroundCycles() {
        var tracker = WMFReadingIntervalTracker()

        // Read for a minute, then navigate deeper — this article is now off screen.
        tracker.viewDidAppear(at: date(0))
        XCTAssertEqual(tracker.viewWillDisappear(at: date(60)), 60)

        // Three background/foreground cycles, half an hour of app usage each, spent elsewhere.
        var totalRecorded: TimeInterval = 0
        var now: TimeInterval = 60
        for _ in 0..<3 {
            tracker.appWillResignActive(at: date(now)).map { totalRecorded += $0 }
            now += 600
            tracker.appDidBecomeActive(at: date(now))
            now += 1800
            tracker.appWillResignActive(at: date(now)).map { totalRecorded += $0 }
        }

        XCTAssertEqual(totalRecorded, 0, "An off-screen article must not record any reading time.")
        XCTAssertFalse(tracker.isTracking)
    }

    func testOnScreenArticleDoesAccumulateAcrossForegroundCycles() {
        var tracker = WMFReadingIntervalTracker()

        tracker.viewDidAppear(at: date(0))
        XCTAssertEqual(tracker.appWillResignActive(at: date(60)), 60)

        // Backgrounded for an hour, then read for another minute.
        tracker.appDidBecomeActive(at: date(3660))
        XCTAssertEqual(tracker.viewWillDisappear(at: date(3720)), 60, "Only the two on-screen minutes count, not the hour in between.")
    }

    /// A second controller further up the navigation stack sees the same notifications as the
    /// visible one. Only the visible one may record time.
    func testOnlyTheVisibleArticleRecordsTimeWhenTwoAreAlive() {
        var visible = WMFReadingIntervalTracker()
        var offScreen = WMFReadingIntervalTracker()

        offScreen.viewDidAppear(at: date(0))
        XCTAssertEqual(offScreen.viewWillDisappear(at: date(30)), 30)
        visible.viewDidAppear(at: date(30))

        // One background/foreground cycle, then the user leaves the visible article.
        XCTAssertEqual(offScreen.appWillResignActive(at: date(90)), nil)
        XCTAssertEqual(visible.appWillResignActive(at: date(90)), 60)

        offScreen.appDidBecomeActive(at: date(100))
        visible.appDidBecomeActive(at: date(100))

        XCTAssertEqual(offScreen.viewWillDisappear(at: date(160)), nil, "The off-screen article recorded phantom time.")
        XCTAssertEqual(visible.viewWillDisappear(at: date(160)), 60)
    }

    // MARK: - Double persist

    /// Leaving an article and backgrounding the app in the same moment used to persist the interval
    /// twice, because the begin date was cleared only after the async write finished.
    func testIntervalIsOnlyReportedOnceWhenTwoClosingEventsArriveTogether() {
        var tracker = WMFReadingIntervalTracker()

        tracker.viewDidAppear(at: date(0))
        XCTAssertEqual(tracker.viewWillDisappear(at: date(60)), 60)
        XCTAssertEqual(tracker.appWillResignActive(at: date(60)), nil, "The same interval was reported twice.")
    }

    func testClosingWithoutAnOpenIntervalReportsNothing() {
        var tracker = WMFReadingIntervalTracker()

        XCTAssertEqual(tracker.viewWillDisappear(at: date(60)), nil)
        XCTAssertEqual(tracker.appWillResignActive(at: date(60)), nil)
    }

    func testRepeatedAppearanceDoesNotRestartAnOpenInterval() {
        var tracker = WMFReadingIntervalTracker()

        tracker.viewDidAppear(at: date(0))
        tracker.viewDidAppear(at: date(45))
        tracker.appDidBecomeActive(at: date(50))

        XCTAssertEqual(tracker.viewWillDisappear(at: date(60)), 60, "The interval should still start from the first appearance.")
    }

    // MARK: - Clamping

    func testIntervalIsClampedToTheMaximum() {
        var tracker = WMFReadingIntervalTracker(maximumInterval: 3600)

        tracker.viewDidAppear(at: date(0))
        XCTAssertEqual(tracker.viewWillDisappear(at: date(40 * 3600)), 3600)
    }

    func testDefaultMaximumIsOneHour() {
        XCTAssertEqual(WMFPageViewsDataController.maximumReadingIntervalSeconds, 3600)

        var tracker = WMFReadingIntervalTracker()
        tracker.viewDidAppear(at: date(0))
        XCTAssertEqual(tracker.viewWillDisappear(at: date(40 * 3600)), 3600)
    }

    func testNonAdvancingClockReportsNothing() {
        var tracker = WMFReadingIntervalTracker()

        tracker.viewDidAppear(at: date(60))
        XCTAssertEqual(tracker.viewWillDisappear(at: date(60)), nil, "A zero length interval is not reading time.")

        // A backwards clock (for example the user changing the device time) must not produce a
        // negative value that would subtract from the stored total.
        tracker.viewDidAppear(at: date(60))
        XCTAssertEqual(tracker.viewWillDisappear(at: date(0)), nil)
    }

    // MARK: - Ordering

    /// The article content can finish loading either side of viewDidAppear. Tracking must start
    /// either way, and must not depend on load order.
    func testTrackingStartsOnAppearanceRegardlessOfContentLoadOrder() {
        var tracker = WMFReadingIntervalTracker()

        tracker.viewDidAppear(at: date(0))
        XCTAssertTrue(tracker.isTracking)

        var other = WMFReadingIntervalTracker()
        other.appDidBecomeActive(at: date(0))
        XCTAssertFalse(other.isTracking, "Becoming active before the article appears must not start tracking.")
        other.viewDidAppear(at: date(10))
        XCTAssertTrue(other.isTracking)
    }
}
