import XCTest
@testable import WMFData
@testable import WMFDataMocks

final class WMFReadingChallengeCompletionDataControllerTests: XCTestCase {

    enum TestsError: Error {
        case missingStore
        case missingDataController
    }

    private var store: WMFCoreDataStore?
    private var pageViewsDataController: WMFPageViewsDataController?
    private var userDefaultsStore: WMFMockKeyValueStore?
    private var legacyDefaults: UserDefaults?

    private lazy var enProject: WMFProject = {
        return .wikipedia(WMFLanguage(languageCode: "en", languageVariantCode: nil))
    }()

    /// First day of the 2026 Reading Challenge window.
    private lazy var challengeStartDate: Date = {
        return DateComponents(calendar: .current, year: 2026, month: 5, day: 11, hour: 12).date!
    }()

    override func setUp() async throws {

        let temporaryDirectory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let store = try await WMFCoreDataStore(appContainerURL: temporaryDirectory)
        self.store = store
        self.pageViewsDataController = try WMFPageViewsDataController(coreDataStore: store)

        self.userDefaultsStore = WMFMockKeyValueStore()

        // A throwaway suite so tests never read or write the real shared app group.
        let legacyDefaults = UserDefaults(suiteName: "org.wikimedia.wikipedia.tests.\(UUID().uuidString)")
        self.legacyDefaults = legacyDefaults

        try await super.setUp()
    }

    private func dataController() throws -> WMFReadingChallengeCompletionDataController {
        guard let store, let userDefaultsStore, let legacyDefaults else {
            throw TestsError.missingStore
        }

        return WMFReadingChallengeCompletionDataController(userDefaultsStore: userDefaultsStore, legacyDefaults: legacyDefaults, coreDataStore: store)
    }

    /// Adds a page view on each of `days` consecutive days, starting `offsetFromStart` days into the challenge window.
    private func addPageViews(days: Int, offsetFromStart: Int = 0) async throws {
        guard let pageViewsDataController else {
            throw TestsError.missingDataController
        }

        let calendar = Calendar.current
        for day in 0..<days {
            guard let timestamp = calendar.date(byAdding: .day, value: offsetFromStart + day, to: challengeStartDate) else {
                continue
            }
            _ = try await pageViewsDataController.addPageView(title: "Cat_\(offsetFromStart)_\(day)", namespaceID: 0, project: enProject, previousPageViewObjectID: nil, timestamp: timestamp)
        }
    }

    func testRecoveryFlagsCompletionForTwentyFiveDayStreak() async throws {
        let dataController = try dataController()
        try await addPageViews(days: 25)

        try await dataController.recoverCompletionIfNeeded()

        XCTAssertTrue(dataController.didCompleteReadingChallenge2026())
        XCTAssertTrue(dataController.didRecoverReadingChallenge2026Completion())
    }

    func testRecoveryDoesNotFlagCompletionForShortStreak() async throws {
        let dataController = try dataController()
        try await addPageViews(days: 24)

        try await dataController.recoverCompletionIfNeeded()

        XCTAssertFalse(dataController.didCompleteReadingChallenge2026())
        XCTAssertTrue(dataController.didRecoverReadingChallenge2026Completion())
    }

    func testRecoveryDoesNotFlagCompletionForBrokenStreak() async throws {
        let dataController = try dataController()

        // 20 days, a one day gap, then 20 more days: 40 reading days but no 25 day streak.
        try await addPageViews(days: 20)
        try await addPageViews(days: 20, offsetFromStart: 21)

        try await dataController.recoverCompletionIfNeeded()

        XCTAssertFalse(dataController.didCompleteReadingChallenge2026())
    }

    func testRecoveryDoesNotCountReadingOutsideChallengeWindow() async throws {
        let dataController = try dataController()

        // Streak starts 20 days before the challenge window opens, so only 5 days land inside it.
        try await addPageViews(days: 25, offsetFromStart: -20)

        try await dataController.recoverCompletionIfNeeded()

        XCTAssertFalse(dataController.didCompleteReadingChallenge2026())
    }

    func testRecoveryHonorsLegacyWidgetCompletionFlag() async throws {
        let dataController = try dataController()

        // No page views at all — the legacy widget flag is the only signal.
        legacyDefaults?.set(true, forKey: "reading-challenge-user-completed")

        try await dataController.recoverCompletionIfNeeded()

        XCTAssertTrue(dataController.didCompleteReadingChallenge2026())
    }

    func testRecoveryOnlyRunsOnce() async throws {
        let dataController = try dataController()

        try await dataController.recoverCompletionIfNeeded()
        XCTAssertFalse(dataController.didCompleteReadingChallenge2026())

        // Page views arriving after recovery has run should not change the saved flag.
        try await addPageViews(days: 25)
        try await dataController.recoverCompletionIfNeeded()

        XCTAssertFalse(dataController.didCompleteReadingChallenge2026())
    }
}
