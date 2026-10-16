import Foundation

/// Decides when a logged-out reader is shown the evergreen account creation prompt
public actor WMFEvergreenAccountCreationDataController {

    // MARK: - Nested Types

    public enum PresentationContext: Sendable {
        case home
        case saved

        case article(isFromDeepLink: Bool)

        var allowsPrompt: Bool {
            switch self {
            case .home, .saved:
                return true
            case .article(let isFromDeepLink):
                return !isFromDeepLink
            }
        }
    }

    public enum PromptOutcome: Sendable {
        case tappedCreateAccount
        case tappedMaybeLater
        case dismissed
    }

    public struct SlideData: Sendable, Equatable {
        public let readingDayCount: Int?
        public let savedArticleCount: Int?
        public let articlesReadThisMonthCount: Int?

        public init(readingDayCount: Int?, savedArticleCount: Int?, articlesReadThisMonthCount: Int?) {
            self.readingDayCount = readingDayCount
            self.savedArticleCount = savedArticleCount
            self.articlesReadThisMonthCount = articlesReadThisMonthCount
        }
    }

    private struct State: Codable {

        /// Merged with reading history to evaluate the windows. Dropped once the reader qualifies.
        var liveAppOpenDays: [Date] = []

        /// Outlives `liveAppOpenDays`, to recognize a second open on the same day.
        var lastLiveAppOpenDay: Date?

        /// Live days only, so a reading history import landing late cannot advance the reader
        /// toward their second impression.
        var liveAppOpenDayCount: Int = 0

        /// Latched, so a cleared reading history cannot take readiness away.
        var isAccountReady: Bool = false

        var impressionCount: Int = 0
        var liveAppOpenDayCountAtMaybeLater: Int?

        /// Survives a cleared reading history, so becoming eligible again does not bring the prompt back.
        var isFinished: Bool = false
    }

    // MARK: - Properties

    public static let shared = WMFEvergreenAccountCreationDataController()
    static let windowLengthInDays = 7
    static let appOpenDaysAfterMaybeLater = 2
    static let maximumImpressions = 2
    static let articlesReadThisMonthWindowInDays = 30

    /// Bounds what a reader who never qualifies accumulates. Far more than the two days inside a
    /// fourteen day span that qualifying needs.
    static let maximumStoredLiveAppOpenDays = 30

    private let calendar: Calendar
    private var _coreDataStore: WMFCoreDataStore?
    private var coreDataStore: WMFCoreDataStore? {
        return _coreDataStore ?? WMFDataEnvironment.current.coreDataStore
    }

    private var _userDefaultsStore: WMFKeyValueStore?
    private var userDefaultsStore: WMFKeyValueStore? {
        return _userDefaultsStore ?? WMFDataEnvironment.current.userDefaultsStore
    }

    // MARK: - Lifecycle

    public init(
        coreDataStore: WMFCoreDataStore? = nil,
        userDefaultsStore: WMFKeyValueStore? = nil,
        calendar: Calendar = .current
    ) {
        self._coreDataStore = coreDataStore
        self._userDefaultsStore = userDefaultsStore
        self.calendar = calendar
    }

    // MARK: - Session

    /// Call once per foreground launch, before the first `shouldShowPrompt` of the session.
    ///
    /// Readiness is evaluated here and nowhere else, and only over days before today, which is what
    /// keeps the prompt out of the session that qualified the reader — however the app orders this
    /// call against its app open recording. Re-evaluating every launch also means a reading history
    /// that arrives late (the legacy page view import runs in a detached task during library
    /// migration 19) is picked up on the next launch instead of being missed for good.
    public func startSession(date: Date = Date()) async {
        var state = loadState()

        guard !state.isAccountReady, !state.isFinished else { return }

        let today = calendar.startOfDay(for: date)
        let days = Set(await readingDays()).union(state.liveAppOpenDays).filter { $0 < today }.sorted()

        guard qualifies(days: days) else { return }

        state.isAccountReady = true
        state.liveAppOpenDays = []
        save(state)
    }

    // MARK: - App Open Tracking

    /// Records that the reader opened the app, from an article view or main tab impression. Only the
    /// first call on a given day counts.
    public func recordAppOpen(date: Date = Date()) {
        var state = loadState()
        let day = calendar.startOfDay(for: date)

        if let lastLiveAppOpenDay = state.lastLiveAppOpenDay,
           calendar.isDate(lastLiveAppOpenDay, inSameDayAs: day) {
            return
        }

        state.lastLiveAppOpenDay = day
        state.liveAppOpenDayCount += 1

        if !state.isAccountReady {
            state.liveAppOpenDays = Array((state.liveAppOpenDays + [day]).sorted().suffix(Self.maximumStoredLiveAppOpenDays))
        }

        save(state)
    }

    public func appOpenDayCount() -> Int {
        return loadState().liveAppOpenDayCount
    }

    public func isAccountReady() -> Bool {
        return loadState().isAccountReady
    }

    // MARK: - Eligibility

    /// - Parameters:
    ///   - context: The surface about to show the prompt.
    ///   - hasPermanentAccount: Whether the reader is logged in to a real account, which lives
    ///     outside WMFData. A temporary account does not count: those readers have nothing to sync
    ///     yet, so the prompt is still for them.
    ///   - isAnotherPromptVisible: Whether a tooltip or prompt is already on screen. This prompt
    ///     ranks below all of them and never shares the screen with one.
    public func shouldShowPrompt(in context: PresentationContext, hasPermanentAccount: Bool, isAnotherPromptVisible: Bool) -> Bool {
        guard !hasPermanentAccount,
              !isAnotherPromptVisible,
              context.allowsPrompt else {
            return false
        }

        let state = loadState()

        guard state.isAccountReady, !state.isFinished else { return false }

        switch state.impressionCount {
        case 0:
            return true
        case 1:
            // Only a "Maybe later" reader gets here, and only once they have opened the app on two
            // more days. Without that recorded count there is nothing to measure, so hold the prompt.
            guard let liveAppOpenDayCountAtMaybeLater = state.liveAppOpenDayCountAtMaybeLater else { return false }

            return state.liveAppOpenDayCount >= liveAppOpenDayCountAtMaybeLater + Self.appOpenDaysAfterMaybeLater
        default:
            return false
        }
    }

    public func recordImpression() {
        var state = loadState()
        state.impressionCount += 1
        save(state)
    }

    public func recordOutcome(_ outcome: PromptOutcome) {
        var state = loadState()

        switch outcome {
        case .tappedCreateAccount, .dismissed:
            state.isFinished = true
        case .tappedMaybeLater:
            if state.impressionCount >= Self.maximumImpressions {
                state.isFinished = true
            } else {
                state.liveAppOpenDayCountAtMaybeLater = state.liveAppOpenDayCount
            }
        }

        save(state)
    }

    // MARK: - Slide Data

    public func slideData() async -> SlideData {
        async let readingDayCount = readingDayCount()
        async let savedArticleCount = savedArticleCount()
        async let articlesReadThisMonthCount = articlesReadThisMonthCount()

        return SlideData(
            readingDayCount: await readingDayCount.nonZeroValue,
            savedArticleCount: await savedArticleCount.nonZeroValue,
            articlesReadThisMonthCount: await articlesReadThisMonthCount.nonZeroValue
        )
    }

    // MARK: - Eligibility Rules

    /// Whether these app open days include one in a seven day window and another in the window that
    /// follows it.
    ///
    /// A day past the second window means the run lapsed, and that day opens a fresh first window,
    /// so a reader who takes a break can still qualify later. The answer depends only on the set of
    /// days, never on the order they were learned, so history that arrives after live tracking has
    /// started still counts.
    private func qualifies(days: [Date]) -> Bool {
        var windowStartDay: Date?

        for day in days {
            guard let currentWindowStartDay = windowStartDay else {
                windowStartDay = day
                continue
            }

            guard let secondWindowStartDay = calendar.date(byAdding: .day, value: Self.windowLengthInDays, to: currentWindowStartDay),
                  let secondWindowEndDay = calendar.date(byAdding: .day, value: Self.windowLengthInDays * 2, to: currentWindowStartDay) else {
                return false
            }

            if day < secondWindowStartDay {
                continue
            }

            if day < secondWindowEndDay {
                return true
            }

            windowStartDay = day
        }

        return false
    }

    // MARK: - Reading Data

    private func readingDays() async -> [Date] {
        guard let pageViewsDataController = try? WMFPageViewsDataController(coreDataStore: coreDataStore) else { return [] }

        return (try? await pageViewsDataController.fetchDistinctPageViewDays(calendar: calendar)) ?? []
    }

    private func readingDayCount() async -> Int {
        return await readingDays().count
    }

    private func savedArticleCount() async -> Int {
        let savedArticlesDataController = WMFSavedArticlesDataController(coreDataStore: coreDataStore)

        return (try? await savedArticlesDataController.fetchSavedArticlesCount()) ?? 0
    }

    private func articlesReadThisMonthCount(date: Date = Date()) async -> Int {
        guard let pageViewsDataController = try? WMFPageViewsDataController(coreDataStore: coreDataStore),
              let startDate = calendar.date(byAdding: .day, value: -Self.articlesReadThisMonthWindowInDays, to: date),
              let pageViewCounts = try? await pageViewsDataController.fetchPageViewCounts(startDate: startDate, endDate: date) else {
            return 0
        }

        return pageViewCounts.reduce(0) { $0 + $1.count }
    }

    // MARK: - Persistence

    private func loadState() -> State {
        return (try? userDefaultsStore?.load(key: WMFUserDefaultsKey.evergreenAccountCreationState.rawValue)) ?? State()
    }

    private func save(_ state: State) {
        try? userDefaultsStore?.save(key: WMFUserDefaultsKey.evergreenAccountCreationState.rawValue, value: state)
    }
}

private extension Int {

    /// A count the prompt has nothing to say about, so its slide drops the number.
    var nonZeroValue: Int? {
        return self > 0 ? self : nil
    }
}
