import Foundation
import Testing
@testable import WMFData

@Suite
struct WMFReadingIntervalTrackerTests {

    private let start = Date(timeIntervalSince1970: 1_700_000_000)

    private func date(_ secondsFromStart: TimeInterval) -> Date {
        return start.addingTimeInterval(secondsFromStart)
    }

    // MARK: - The regression

    /// The bug: several article view controllers stay alive at once and all observe the app-wide
    /// active notification, so off-screen articles resumed timing and each recorded the full length
    /// of every foreground session.
    @Test
    func offScreenArticleDoesNotAccumulateAcrossForegroundCycles() {
        var tracker = WMFReadingIntervalTracker()

        // Read for a minute, then navigate deeper — this article is now off screen.
        tracker.viewDidAppear(at: date(0))
        #expect(tracker.viewWillDisappear(at: date(60)) == 60)

        // Three background/foreground cycles, half an hour of app usage each, spent elsewhere.
        var totalRecorded: TimeInterval = 0
        var now: TimeInterval = 60
        for _ in 0..<3 {
            totalRecorded += tracker.appWillResignActive(at: date(now)) ?? 0
            now += 600
            tracker.appDidBecomeActive(at: date(now))
            now += 1800
            totalRecorded += tracker.appWillResignActive(at: date(now)) ?? 0
        }

        #expect(totalRecorded == 0, "An off-screen article must not record any reading time.")
        #expect(tracker.isTracking == false)
    }

    @Test
    func onScreenArticleDoesAccumulateAcrossForegroundCycles() {
        var tracker = WMFReadingIntervalTracker()

        tracker.viewDidAppear(at: date(0))
        #expect(tracker.appWillResignActive(at: date(60)) == 60)

        // Backgrounded for an hour, then read for another minute.
        tracker.appDidBecomeActive(at: date(3660))
        #expect(tracker.viewWillDisappear(at: date(3720)) == 60, "Only the two on-screen minutes count, not the hour in between.")
    }

    /// A second controller further up the navigation stack sees the same notifications as the
    /// visible one. Only the visible one may record time.
    @Test
    func onlyTheVisibleArticleRecordsTimeWhenTwoAreAlive() {
        var visible = WMFReadingIntervalTracker()
        var offScreen = WMFReadingIntervalTracker()

        offScreen.viewDidAppear(at: date(0))
        #expect(offScreen.viewWillDisappear(at: date(30)) == 30)
        visible.viewDidAppear(at: date(30))

        // One background/foreground cycle, then the user leaves the visible article.
        #expect(offScreen.appWillResignActive(at: date(90)) == nil)
        #expect(visible.appWillResignActive(at: date(90)) == 60)

        offScreen.appDidBecomeActive(at: date(100))
        visible.appDidBecomeActive(at: date(100))

        #expect(offScreen.viewWillDisappear(at: date(160)) == nil, "The off-screen article recorded phantom time.")
        #expect(visible.viewWillDisappear(at: date(160)) == 60)
    }

    // MARK: - Double persist

    /// Leaving an article and backgrounding the app in the same moment used to persist the interval
    /// twice, because the begin date was cleared only after the async write finished.
    @Test
    func intervalIsOnlyReportedOnceWhenTwoClosingEventsArriveTogether() {
        var tracker = WMFReadingIntervalTracker()

        tracker.viewDidAppear(at: date(0))
        #expect(tracker.viewWillDisappear(at: date(60)) == 60)
        #expect(tracker.appWillResignActive(at: date(60)) == nil, "The same interval was reported twice.")
    }

    @Test
    func closingWithoutAnOpenIntervalReportsNothing() {
        var tracker = WMFReadingIntervalTracker()

        #expect(tracker.viewWillDisappear(at: date(60)) == nil)
        #expect(tracker.appWillResignActive(at: date(60)) == nil)
    }

    @Test
    func repeatedAppearanceDoesNotRestartAnOpenInterval() {
        var tracker = WMFReadingIntervalTracker()

        tracker.viewDidAppear(at: date(0))
        tracker.viewDidAppear(at: date(45))
        tracker.appDidBecomeActive(at: date(50))

        #expect(tracker.viewWillDisappear(at: date(60)) == 60, "The interval should still start from the first appearance.")
    }

    // MARK: - Clamping

    @Test(arguments: [3600 as TimeInterval, 1800, 60])
    func intervalIsClampedToTheMaximum(maximumInterval: TimeInterval) {
        var tracker = WMFReadingIntervalTracker(maximumInterval: maximumInterval)

        tracker.viewDidAppear(at: date(0))
        #expect(tracker.viewWillDisappear(at: date(40 * 3600)) == maximumInterval)
    }

    @Test
    func defaultMaximumIsOneHour() {
        #expect(WMFPageViewsDataController.maximumReadingIntervalSeconds == 3600)

        var tracker = WMFReadingIntervalTracker()
        tracker.viewDidAppear(at: date(0))
        #expect(tracker.viewWillDisappear(at: date(40 * 3600)) == 3600)
    }

    /// A zero length interval is not reading time, and a backwards clock (the user changing the
    /// device time) must not produce a negative value that would subtract from the stored total.
    @Test(arguments: [0 as TimeInterval, -60, -86400])
    func nonAdvancingClockReportsNothing(offset: TimeInterval) {
        var tracker = WMFReadingIntervalTracker()

        tracker.viewDidAppear(at: date(86400))
        #expect(tracker.viewWillDisappear(at: date(86400 + offset)) == nil)
    }

    // MARK: - Ordering

    /// The article content can finish loading either side of viewDidAppear. Tracking must start
    /// either way, and must not depend on load order.
    @Test
    func trackingStartsOnAppearanceRegardlessOfContentLoadOrder() {
        var appearedFirst = WMFReadingIntervalTracker()
        appearedFirst.viewDidAppear(at: date(0))
        #expect(appearedFirst.isTracking)

        var becameActiveFirst = WMFReadingIntervalTracker()
        becameActiveFirst.appDidBecomeActive(at: date(0))
        #expect(becameActiveFirst.isTracking == false, "Becoming active before the article appears must not start tracking.")
        becameActiveFirst.viewDidAppear(at: date(10))
        #expect(becameActiveFirst.isTracking)
    }
}
