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
/// Dates are passed in rather than read from a clock so tests can drive them.
public struct WMFReadingIntervalTracker: Sendable, Equatable {

    private var isOnScreen = false
    private var beganViewingDate: Date?
    private let maximumInterval: TimeInterval

    /// - Parameter maximumInterval: Longest interval that will be reported. Anything longer is
    ///   assumed to be an interval we failed to close — for example an iPad window that stays
    ///   active while the user works in another app — rather than real reading, so it is clamped.
    public init(maximumInterval: TimeInterval = WMFPageViewsDataController.maximumReadingIntervalSeconds) {
        self.maximumInterval = maximumInterval
    }

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

    /// Ends the open interval and returns its length, clamped. Clearing the begin date here — rather
    /// than after the caller finishes persisting — is what stops one interval being recorded twice
    /// when two closing events arrive together (leaving an article and backgrounding the app in the
    /// same moment).
    private mutating func closeInterval(at date: Date) -> TimeInterval? {
        guard let beganViewingDate else { return nil }

        self.beganViewingDate = nil

        let elapsed = date.timeIntervalSince(beganViewingDate)
        guard elapsed > 0 else { return nil }

        return min(elapsed, maximumInterval)
    }
}
