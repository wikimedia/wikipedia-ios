import Foundation

/// Tracks how long an article is actually being read, as a series of closed intervals.
///
/// An interval is open only while the article is both on screen and the app is active. Callers feed
/// in the four lifecycle events; the two that can close an interval return the seconds to persist,
/// or `nil` when there is nothing to record.
///
/// This exists as a separate type, rather than as state on a view controller, so the rules can be
/// tested directly. The bug it was extracted for (T-ticket: Activity tab reporting more reading
/// hours than exist in the period) came from resuming an interval on an off-screen article: several
/// article view controllers stay alive at once and all of them observe the app-wide active
/// notification, so each one recorded the full length of every foreground session. Hence
/// `appDidBecomeActive(at:)` resumes only when `isOnScreen` is true.
///
/// Intervals are reported at their full length — there is no upper bound. A reader who spends three
/// hours on one article gets three hours. The known cost is that an interval we fail to close is
/// reported in full too: an article left on screen with the device kept awake keeps its interval open
/// until the app is backgrounded or the article is navigated away from. Auto-lock closes it in the
/// ordinary case (the app never disables the idle timer), so this needs an unusual device setup.
/// Capping was considered and rejected, because bounding that case also truncates genuine long reads.
///
/// Dates are passed in rather than read from a clock so tests can drive them.
public struct WMFReadingIntervalTracker: Sendable, Equatable {

    private var isOnScreen = false
    private var beganViewingDate: Date?

    public init() {}

    /// Whether an interval is currently open. Exposed for tests and diagnostics.
    public var isTracking: Bool {
        return beganViewingDate != nil
    }

    /// The article became visible. Opens an interval if the app is active.
    public mutating func viewDidAppear(at date: Date) {
        isOnScreen = true
        beginIfNeeded(at: date)
    }

    /// The article is going away. Closes any open interval.
    public mutating func viewWillDisappear(at date: Date) -> TimeInterval? {
        isOnScreen = false
        return closeInterval(at: date)
    }

    /// The app became active. Resumes only if this article is the one on screen — an off-screen
    /// article must not accumulate reading time.
    public mutating func appDidBecomeActive(at date: Date) {
        guard isOnScreen else { return }
        beginIfNeeded(at: date)
    }

    /// The app is no longer active. Closes any open interval.
    public mutating func appWillResignActive(at date: Date) -> TimeInterval? {
        return closeInterval(at: date)
    }

    // MARK: - Private

    private mutating func beginIfNeeded(at date: Date) {
        guard beganViewingDate == nil else { return }
        beganViewingDate = date
    }

    /// Ends the open interval and returns its length. Clearing the begin date here — rather than after
    /// the caller finishes persisting — is what stops one interval being recorded twice when two
    /// closing events arrive together (leaving an article and backgrounding the app in the same
    /// moment).
    ///
    /// A non-positive length is discarded rather than reported. That covers a zero length interval,
    /// and guards against the device clock moving backwards producing a negative value that would
    /// subtract from the stored total.
    private mutating func closeInterval(at date: Date) -> TimeInterval? {
        guard let beganViewingDate else { return nil }

        self.beganViewingDate = nil

        let elapsed = date.timeIntervalSince(beganViewingDate)
        guard elapsed > 0 else { return nil }

        return elapsed
    }
}
