import Foundation
import Testing
import WMFDataMocks
import WMFDataTestSupport
@testable import WMFData

@Suite
struct WMFEvergreenAccountCreationDataControllerTests {

    private let fixture = WMFDataTestFixture()
    private let enProject = WMFProject.wikipedia(WMFLanguage(languageCode: "en", languageVariantCode: nil))

    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .current
        return calendar
    }

    /// A fixed anchor, so a test's day arithmetic never straddles a real midnight.
    private var day0: Date {
        calendar.date(from: DateComponents(year: 2026, month: 3, day: 1, hour: 9))!
    }

    private func day(_ offset: Int) -> Date {
        calendar.date(byAdding: .day, value: offset, to: day0)!
    }

    /// A controller with no Core Data store: eligibility never reads one, and an absent store makes
    /// the backfill a no-op, which is what a fresh install looks like.
    private func makeController(userDefaultsStore: WMFKeyValueStore = WMFMockKeyValueStore()) -> WMFEvergreenAccountCreationDataController {
        WMFEvergreenAccountCreationDataController(coreDataStore: nil, userDefaultsStore: userDefaultsStore, calendar: calendar)
    }

    /// Takes a reader from a fresh install to account-ready: an open in the first window, an open in
    /// the second, then the following session.
    private func makeAccountReadyController(userDefaultsStore: WMFKeyValueStore = WMFMockKeyValueStore()) async -> WMFEvergreenAccountCreationDataController {
        let dataController = makeController(userDefaultsStore: userDefaultsStore)
        await dataController.startSession(date: day(0))
        await dataController.recordAppOpen(date: day(0))
        await dataController.recordAppOpen(date: day(8))
        await dataController.startSession(date: day(9))

        // Asserted here so that a test expecting the prompt to be suppressed cannot pass on a
        // reader who was never eligible to begin with.
        #expect(await dataController.isAccountReady(), "The tests built on this reader are only meaningful once they are account ready.")

        return dataController
    }

    // MARK: - Becoming Account Ready

    @Test
    func openingTheAppInOneWindowIsNotEnough() async throws {
        let dataController = makeController()
        await dataController.startSession()

        // Four days of reading, all inside the first seven day window.
        for offset in [0, 1, 4, 6] {
            await dataController.recordAppOpen(date: day(offset))
        }
        await dataController.startSession()

        #expect(await dataController.isAccountReady() == false)
        #expect(await dataController.shouldShowPrompt(in: .home, hasPermanentAccount: false, isAnotherPromptVisible: false) == false)
    }

    @Test
    func openingTheAppInTheSecondWindowQualifiesTheReader() async throws {
        let dataController = makeController()
        await dataController.startSession()
        await dataController.recordAppOpen(date: day(0))
        await dataController.recordAppOpen(date: day(7))
        await dataController.startSession()

        #expect(await dataController.isAccountReady())
    }

    /// The day count the second impression is measured against comes from live opens only, so a
    /// history import cannot push a "Maybe later" reader toward it.
    @Test
    func onlyLiveOpensCountTowardTheAppOpenDayCount() async throws {
        try await fixture.withConfiguredEnvironment(configure: {
            WMFDataEnvironment.current.userDefaultsStore = WMFMockKeyValueStore()
        }, operation: {
            let store = try await fixture.makeTemporaryCoreDataStore()
            let pageViewsDataController = try WMFPageViewsDataController(coreDataStore: store, userDefaultsStore: WMFMockKeyValueStore())

            for offset in [-20, -12, -4] {
                _ = try await pageViewsDataController.addPageView(title: "Cat\(offset)", namespaceID: 0, project: enProject, previousPageViewObjectID: nil, timestamp: day(offset))
            }

            let dataController = WMFEvergreenAccountCreationDataController(coreDataStore: store, userDefaultsStore: WMFMockKeyValueStore(), calendar: calendar)
            await dataController.startSession()
            await dataController.recordAppOpen(date: day(0))

            #expect(await dataController.appOpenDayCount() == 1)
        })
    }

    /// The threshold is crossed mid-session, and the prompt waits for the next one.
    @Test
    func promptWaitsForTheSessionAfterTheThresholdIsCrossed() async throws {
        let dataController = makeController()
        await dataController.startSession()
        await dataController.recordAppOpen(date: day(0))
        await dataController.recordAppOpen(date: day(9))

        #expect(await dataController.shouldShowPrompt(in: .home, hasPermanentAccount: false, isAnotherPromptVisible: false) == false, "The qualifying session must not show the prompt.")

        await dataController.startSession()

        #expect(await dataController.shouldShowPrompt(in: .home, hasPermanentAccount: false, isAnotherPromptVisible: false))
    }

    /// The session that qualified the reader must not show the prompt, whichever order the app
    /// records its app open and starts its session in.
    @Test
    func theQualifyingDayItselfDoesNotOpenThePrompt() async throws {
        let dataController = makeController()
        await dataController.startSession(date: day(0))
        await dataController.recordAppOpen(date: day(0))
        await dataController.recordAppOpen(date: day(8))

        await dataController.startSession(date: day(8))
        #expect(await dataController.isAccountReady() == false, "Day 8 is the day the threshold was crossed.")

        await dataController.startSession(date: day(9))
        #expect(await dataController.isAccountReady())
    }

    /// A reader who skips a week has not opened the app in two consecutive windows, so the day they
    /// come back opens a fresh first window rather than disqualifying them forever.
    @Test
    func aLapsedRunStartsOver() async throws {
        let dataController = makeController()
        await dataController.startSession()
        await dataController.recordAppOpen(date: day(0))
        await dataController.recordAppOpen(date: day(20))
        await dataController.startSession()

        #expect(await dataController.isAccountReady() == false, "Day 20 is past the second window, so it cannot qualify.")

        // Day 20 is now the first window, and day 28 falls in its second window.
        await dataController.recordAppOpen(date: day(28))
        await dataController.startSession()

        #expect(await dataController.isAccountReady())
    }

    @Test
    func repeatedOpensOnOneDayCountOnce() async throws {
        let dataController = makeController()
        await dataController.startSession()

        await dataController.recordAppOpen(date: day(0))
        await dataController.recordAppOpen(date: calendar.date(byAdding: .hour, value: 4, to: day(0))!)
        await dataController.recordAppOpen(date: calendar.date(byAdding: .hour, value: 8, to: day(0))!)

        #expect(await dataController.appOpenDayCount() == 1)
    }

    // MARK: - Where The Prompt May Show

    @Test
    func promptShowsOnHomeSavedAndInternallyLinkedArticles() async throws {
        let dataController = await makeAccountReadyController()

        #expect(await dataController.shouldShowPrompt(in: .home, hasPermanentAccount: false, isAnotherPromptVisible: false))
        #expect(await dataController.shouldShowPrompt(in: .saved, hasPermanentAccount: false, isAnotherPromptVisible: false))
        #expect(await dataController.shouldShowPrompt(in: .article(isFromDeepLink: false), hasPermanentAccount: false, isAnotherPromptVisible: false))
    }

    @Test
    func promptIsSuppressedOnArticlesReachedFromADeepLink() async throws {
        let dataController = await makeAccountReadyController()

        #expect(await dataController.shouldShowPrompt(in: .article(isFromDeepLink: true), hasPermanentAccount: false, isAnotherPromptVisible: false) == false)
    }

    @Test
    func promptIsSuppressedForReadersWithAPermanentAccount() async throws {
        let dataController = await makeAccountReadyController()

        #expect(await dataController.shouldShowPrompt(in: .home, hasPermanentAccount: true, isAnotherPromptVisible: false) == false)
    }

    /// A temporary account has nothing to sync yet, so those readers are still shown the prompt. The
    /// app passes `authStateIsPermanent`, which is false for them.
    @Test
    func promptShowsForReadersOnATemporaryAccount() async throws {
        let dataController = await makeAccountReadyController()

        #expect(await dataController.shouldShowPrompt(in: .home, hasPermanentAccount: false, isAnotherPromptVisible: false))
    }

    /// This prompt ranks below every other tooltip and prompt, and never shares the screen with one.
    @Test
    func promptIsSuppressedWhileAnotherPromptIsVisible() async throws {
        let dataController = await makeAccountReadyController()

        #expect(await dataController.shouldShowPrompt(in: .home, hasPermanentAccount: false, isAnotherPromptVisible: true) == false)
    }

    // MARK: - Impression Cap

    @Test
    func aDismissedPromptNeverReturns() async throws {
        let dataController = await makeAccountReadyController()

        await dataController.recordImpression()
        await dataController.recordOutcome(.dismissed)

        // Plenty more reading, which must not bring it back.
        for offset in [15, 16, 17, 30] {
            await dataController.recordAppOpen(date: day(offset))
        }
        await dataController.startSession()

        #expect(await dataController.shouldShowPrompt(in: .home, hasPermanentAccount: false, isAnotherPromptVisible: false) == false)
    }

    @Test
    func tappingCreateAccountEndsThePrompt() async throws {
        let dataController = await makeAccountReadyController()

        await dataController.recordImpression()
        await dataController.recordOutcome(.tappedCreateAccount)
        await dataController.recordAppOpen(date: day(15))
        await dataController.recordAppOpen(date: day(16))
        await dataController.startSession()

        #expect(await dataController.shouldShowPrompt(in: .home, hasPermanentAccount: false, isAnotherPromptVisible: false) == false)
    }

    /// "Maybe later" buys a second impression, but only after two more app open days.
    @Test
    func maybeLaterShowsThePromptOnceMoreAfterTwoMoreAppOpenDays() async throws {
        let dataController = await makeAccountReadyController()

        await dataController.recordImpression()
        await dataController.recordOutcome(.tappedMaybeLater)

        #expect(await dataController.shouldShowPrompt(in: .home, hasPermanentAccount: false, isAnotherPromptVisible: false) == false, "Same day as the first impression.")

        await dataController.recordAppOpen(date: day(15))
        #expect(await dataController.shouldShowPrompt(in: .home, hasPermanentAccount: false, isAnotherPromptVisible: false) == false, "One more app open day is not two.")

        await dataController.recordAppOpen(date: day(16))
        #expect(await dataController.shouldShowPrompt(in: .home, hasPermanentAccount: false, isAnotherPromptVisible: false), "Two more app open days, so the second impression is due.")
    }

    @Test
    func maybeLaterOnTheSecondImpressionEndsThePrompt() async throws {
        let dataController = await makeAccountReadyController()

        await dataController.recordImpression()
        await dataController.recordOutcome(.tappedMaybeLater)
        await dataController.recordAppOpen(date: day(15))
        await dataController.recordAppOpen(date: day(16))

        await dataController.recordImpression()
        await dataController.recordOutcome(.tappedMaybeLater)

        for offset in [17, 18, 19, 40] {
            await dataController.recordAppOpen(date: day(offset))
        }
        await dataController.startSession()

        #expect(await dataController.shouldShowPrompt(in: .home, hasPermanentAccount: false, isAnotherPromptVisible: false) == false, "Two impressions is the maximum.")
    }

    // MARK: - Existing Readers

    /// Readers who already met the requirements before the feature shipped qualify from their
    /// reading history, on the session that runs the backfill rather than a later one.
    @Test
    func existingReadersQualifyFromReadingHistory() async throws {
        try await fixture.withConfiguredEnvironment(configure: {
            WMFDataEnvironment.current.userDefaultsStore = WMFMockKeyValueStore()
        }, operation: {
            let store = try await fixture.makeTemporaryCoreDataStore()
            let pageViewsDataController = try WMFPageViewsDataController(coreDataStore: store, userDefaultsStore: WMFMockKeyValueStore())

            // Reading in two consecutive seven day windows.
            _ = try await pageViewsDataController.addPageView(title: "Cat", namespaceID: 0, project: enProject, previousPageViewObjectID: nil, timestamp: day(-20))
            _ = try await pageViewsDataController.addPageView(title: "Dog", namespaceID: 0, project: enProject, previousPageViewObjectID: nil, timestamp: day(-12))

            let dataController = WMFEvergreenAccountCreationDataController(coreDataStore: store, userDefaultsStore: WMFMockKeyValueStore(), calendar: calendar)
            await dataController.startSession()

            #expect(await dataController.isAccountReady())
            #expect(await dataController.shouldShowPrompt(in: .home, hasPermanentAccount: false, isAnotherPromptVisible: false), "These readers see the prompt now, not a session later.")
        })
    }

    @Test
    func existingReadersWithOnlyOneWindowOfHistoryDoNotQualify() async throws {
        try await fixture.withConfiguredEnvironment(configure: {
            WMFDataEnvironment.current.userDefaultsStore = WMFMockKeyValueStore()
        }, operation: {
            let store = try await fixture.makeTemporaryCoreDataStore()
            let pageViewsDataController = try WMFPageViewsDataController(coreDataStore: store, userDefaultsStore: WMFMockKeyValueStore())

            _ = try await pageViewsDataController.addPageView(title: "Cat", namespaceID: 0, project: enProject, previousPageViewObjectID: nil, timestamp: day(-6))
            _ = try await pageViewsDataController.addPageView(title: "Dog", namespaceID: 0, project: enProject, previousPageViewObjectID: nil, timestamp: day(-2))

            let dataController = WMFEvergreenAccountCreationDataController(coreDataStore: store, userDefaultsStore: WMFMockKeyValueStore(), calendar: calendar)
            await dataController.startSession()

            #expect(await dataController.isAccountReady() == false)
        })
    }

    /// The legacy page view import runs in a detached task during library migration 19, so the
    /// first session after an update can see an empty store. A later session must still recognize
    /// the reader rather than having burned a one-shot backfill.
    @Test
    func historyThatArrivesAfterTheFirstSessionIsStillPickedUp() async throws {
        try await fixture.withConfiguredEnvironment(configure: {
            WMFDataEnvironment.current.userDefaultsStore = WMFMockKeyValueStore()
        }, operation: {
            let store = try await fixture.makeTemporaryCoreDataStore()
            let pageViewsDataController = try WMFPageViewsDataController(coreDataStore: store, userDefaultsStore: WMFMockKeyValueStore())
            let dataController = WMFEvergreenAccountCreationDataController(coreDataStore: store, userDefaultsStore: WMFMockKeyValueStore(), calendar: calendar)

            // The update launch, with the import still in flight.
            await dataController.startSession()
            #expect(await dataController.isAccountReady() == false)

            _ = try await pageViewsDataController.addPageView(title: "Cat", namespaceID: 0, project: enProject, previousPageViewObjectID: nil, timestamp: day(-20))
            _ = try await pageViewsDataController.addPageView(title: "Dog", namespaceID: 0, project: enProject, previousPageViewObjectID: nil, timestamp: day(-12))

            await dataController.startSession()

            #expect(await dataController.isAccountReady())
        })
    }

    /// History older than the live days already recorded must still qualify the reader: readiness is
    /// a question about the set of days, not the order they were learned in.
    @Test
    func historyOlderThanRecordedLiveDaysStillQualifiesTheReader() async throws {
        try await fixture.withConfiguredEnvironment(configure: {
            WMFDataEnvironment.current.userDefaultsStore = WMFMockKeyValueStore()
        }, operation: {
            let store = try await fixture.makeTemporaryCoreDataStore()
            let pageViewsDataController = try WMFPageViewsDataController(coreDataStore: store, userDefaultsStore: WMFMockKeyValueStore())
            let dataController = WMFEvergreenAccountCreationDataController(coreDataStore: store, userDefaultsStore: WMFMockKeyValueStore(), calendar: calendar)

            // A live open lands first, before any history is available.
            await dataController.startSession()
            await dataController.recordAppOpen(date: day(0))

            // The import then brings in a day seven days before it, which completes the pair.
            _ = try await pageViewsDataController.addPageView(title: "Cat", namespaceID: 0, project: enProject, previousPageViewObjectID: nil, timestamp: day(-7))

            await dataController.startSession()

            #expect(await dataController.isAccountReady())
        })
    }

    /// Re-evaluating every launch has to be idempotent.
    @Test
    func repeatedSessionsDoNotDoubleCountHistory() async throws {
        try await fixture.withConfiguredEnvironment(configure: {
            WMFDataEnvironment.current.userDefaultsStore = WMFMockKeyValueStore()
        }, operation: {
            let store = try await fixture.makeTemporaryCoreDataStore()
            let pageViewsDataController = try WMFPageViewsDataController(coreDataStore: store, userDefaultsStore: WMFMockKeyValueStore())

            _ = try await pageViewsDataController.addPageView(title: "Cat", namespaceID: 0, project: enProject, previousPageViewObjectID: nil, timestamp: day(-6))

            let dataController = WMFEvergreenAccountCreationDataController(coreDataStore: store, userDefaultsStore: WMFMockKeyValueStore(), calendar: calendar)

            for _ in 0..<5 {
                await dataController.startSession()
            }

            #expect(await dataController.isAccountReady() == false, "One reading day cannot qualify, however many times it is evaluated.")
            #expect(await dataController.appOpenDayCount() == 0, "History days are not live app opens.")
        })
    }

    /// Clearing reading history and becoming eligible again must not bring back a finished prompt,
    /// so the impression state lives in user defaults rather than in the reading data.
    @Test
    func clearingReadingHistoryDoesNotBringBackAFinishedPrompt() async throws {
        let userDefaultsStore = WMFMockKeyValueStore()
        let dataController = await makeAccountReadyController(userDefaultsStore: userDefaultsStore)

        await dataController.recordImpression()
        await dataController.recordOutcome(.dismissed)

        // A new controller over the same defaults, as if the reader wiped history and requalified.
        let laterDataController = makeController(userDefaultsStore: userDefaultsStore)
        await laterDataController.recordAppOpen(date: day(40))
        await laterDataController.recordAppOpen(date: day(48))
        await laterDataController.startSession()

        #expect(await laterDataController.shouldShowPrompt(in: .home, hasPermanentAccount: false, isAnotherPromptVisible: false) == false)
    }

    // MARK: - Slide Data

    @Test
    func slideDataReportsReadingDaysSavedArticlesAndArticlesReadThisMonth() async throws {
        try await fixture.withConfiguredEnvironment(configure: {
            WMFDataEnvironment.current.userDefaultsStore = WMFMockKeyValueStore()
        }, operation: {
            let store = try await fixture.makeTemporaryCoreDataStore()
            let pageViewsDataController = try WMFPageViewsDataController(coreDataStore: store, userDefaultsStore: WMFMockKeyValueStore())

            let now = Date()
            let today = calendar.startOfDay(for: now).addingTimeInterval(3600)
            let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
            let longAgo = calendar.date(byAdding: .day, value: -100, to: today)!

            // Three distinct reading days, two of them inside the last thirty days.
            _ = try await pageViewsDataController.addPageView(title: "Cat", namespaceID: 0, project: enProject, previousPageViewObjectID: nil, timestamp: today)
            _ = try await pageViewsDataController.addPageView(title: "Dog", namespaceID: 0, project: enProject, previousPageViewObjectID: nil, timestamp: yesterday)
            _ = try await pageViewsDataController.addPageView(title: "Bird", namespaceID: 0, project: enProject, previousPageViewObjectID: nil, timestamp: longAgo)

            let dataController = WMFEvergreenAccountCreationDataController(coreDataStore: store, userDefaultsStore: WMFMockKeyValueStore(), calendar: calendar)
            let slideData = await dataController.slideData()

            #expect(slideData.readingDayCount == 3)
            #expect(slideData.articlesReadThisMonthCount == 2, "The hundred day old read is outside the window.")
            #expect(slideData.savedArticleCount == nil, "Nothing is saved, so the slide drops the number.")
        })
    }

    @Test
    func slideDataLeavesOutNumbersTheReaderHasNoDataFor() async throws {
        try await fixture.withConfiguredEnvironment(configure: {
            WMFDataEnvironment.current.userDefaultsStore = WMFMockKeyValueStore()
        }, operation: {
            let store = try await fixture.makeTemporaryCoreDataStore()

            let dataController = WMFEvergreenAccountCreationDataController(coreDataStore: store, userDefaultsStore: WMFMockKeyValueStore(), calendar: calendar)
            let slideData = await dataController.slideData()

            #expect(slideData == WMFEvergreenAccountCreationDataController.SlideData(readingDayCount: nil, savedArticleCount: nil, articlesReadThisMonthCount: nil))
        })
    }
}
