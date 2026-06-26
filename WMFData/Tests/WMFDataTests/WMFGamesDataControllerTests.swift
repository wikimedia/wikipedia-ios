import XCTest
import WMFDataTestSupport
@testable import WMFData
@testable import WMFDataMocks

final class WMFGamesDataControllerTests: XCTestCase {

    // MARK: - Properties

    private let fixture = WMFDataTestFixture()
    var store: WMFCoreDataStore?
    var dataController: WMFGamesDataController?

    lazy var enProject: WMFProject = {
        let language = WMFLanguage(languageCode: "en", languageVariantCode: nil)
        return .wikipedia(language)
    }()

    /// Date string with enough On This Day events in the May 7 fixture (55 events).
    let dateWithEnoughEvents = "2026-05-07"

    /// Date string for the Feb 21 fixture that only has 3 events (insufficient for 5 pairs).
    let dateWithFewEvents = "2026-02-21"

    // MARK: - Setup

    override func setUp() async throws {
        try await super.setUp()
        await fixture.setUp()
        let store = try await fixture.makeTemporaryCoreDataStore()
        self.store = store

        WMFDataEnvironment.current.appData = WMFAppData(appLanguages: [
            WMFLanguage(languageCode: "en", languageVariantCode: nil)
        ])
        await fixture.resetWMFDataTestState()

        self.dataController = WMFGamesDataController(coreDataStore: store)
    }

    override func tearDown() async throws {
        await fixture.tearDown()
        try await super.tearDown()
    }

    // MARK: - Helper Factories

    private func makeOnThisDayController(fixture: String) -> WMFOnThisDayDataController {
        let mockService = WMFMockBasicService(jsonResourceName: fixture)
        return WMFOnThisDayDataController(basicService: mockService)
    }

    private func onThisDayControllerWithEnoughEvents() -> WMFOnThisDayDataController {
        makeOnThisDayController(fixture: "onthisday-events-05-07-get")
    }

    private func onThisDayControllerWithFewEvents() -> WMFOnThisDayDataController {
        makeOnThisDayController(fixture: "onthisday-events-02-21-get")
    }

    // MARK: - fetchOrStartWhichCameFirstDailySession Tests

    func testFetchOrStartCreatesNewSessionWithFiveQuestions() async throws {
        guard let dataController else { throw TestsError.missingDataController }

        let (gameState, _) = try await dataController.fetchOrStartWhichCameFirstDailySession(
            date: dateWithEnoughEvents,
            project: enProject,
            onThisDayDataController: onThisDayControllerWithEnoughEvents()
        )

        XCTAssertEqual(gameState.questions.count, 5)
        XCTAssertTrue(gameState.answers.isEmpty)
    }

    func testFetchOrStartResumesExistingSessionWithoutNewAPICall() async throws {
        guard let dataController else { throw TestsError.missingDataController }

        let otdController = onThisDayControllerWithEnoughEvents()

        let (firstState, _) = try await dataController.fetchOrStartWhichCameFirstDailySession(
            date: dateWithEnoughEvents,
            project: enProject,
            onThisDayDataController: otdController
        )

        guard let firstQuestion = firstState.questions.first else {
            XCTFail("Expected at least one question")
            return
        }

        _ = try await dataController.submitWhichCameFirstAnswer(
            sessionIdentifier: try await sessionIdentifier(for: dateWithEnoughEvents),
            questionIdentifier: firstQuestion.id,
            pickedOption: firstQuestion.correctAnswer
        )

        let (resumedState, _) = try await dataController.fetchOrStartWhichCameFirstDailySession(
            date: dateWithEnoughEvents,
            project: enProject,
            onThisDayDataController: makeOnThisDayController(fixture: "onthisday-events-05-07-get")
        )

        XCTAssertEqual(resumedState.questions.count, 5)
        XCTAssertEqual(resumedState.answers.count, 1)
        XCTAssertEqual(resumedState.answers[firstQuestion.id.uuidString], firstQuestion.correctAnswer)
    }

    func testFetchOrStartQuestionsHaveDistinctYears() async throws {
        guard let dataController else { throw TestsError.missingDataController }

        let (gameState, _) = try await dataController.fetchOrStartWhichCameFirstDailySession(
            date: dateWithEnoughEvents,
            project: enProject,
            onThisDayDataController: onThisDayControllerWithEnoughEvents()
        )

        for question in gameState.questions {
            XCTAssertNotEqual(
                question.optionA.date,
                question.optionB.date,
                "Each question's two options should have different dates"
            )
        }
    }

    func testFetchOrStartCorrectAnswerIsValidOption() async throws {
        guard let dataController else { throw TestsError.missingDataController }

        let (gameState, _) = try await dataController.fetchOrStartWhichCameFirstDailySession(
            date: dateWithEnoughEvents,
            project: enProject,
            onThisDayDataController: onThisDayControllerWithEnoughEvents()
        )

        for question in gameState.questions {
            XCTAssertTrue(
                question.correctAnswer == "A" || question.correctAnswer == "B",
                "correctAnswer must be 'A' or 'B', got '\(question.correctAnswer)'"
            )
        }
    }

    // MARK: - makeWhichCameFirstQuestions BC Date Filtering Tests

    /// Builds an event with a single page so it passes the `!pages.isEmpty` filter.
    private func makeEvent(text: String, year: Int) -> WMFOnThisDayEvent {
        let page = WMFOnThisDayPage(
            title: text,
            description: nil,
            extract: nil,
            thumbnail: nil,
            contentUrls: nil
        )
        return WMFOnThisDayEvent(text: text, year: year, pages: [page])
    }

    func testQuestionsExcludeBCEvents() {
        let bcEvents = [
            makeEvent(text: "Battle of Thermopylae", year: -500),
            makeEvent(text: "Founding of Rome", year: -100),
            makeEvent(text: "Julius Caesar born", year: -1)
        ]
        let yearZeroEvent = makeEvent(text: "Year Zero Event", year: 0)
        let adEventTitles = ["Alpha","Beta","Gamma","Delta","Epsilon","Zeta","Eta","Theta","Iota","Kappa","Lambda","Mu","Nu","Xi","Omicron","Pi","Rho","Sigma","Tau","Upsilon"]
        let adEvents = (0...19).map { makeEvent(text: "AD Event \(adEventTitles[$0])", year: ($0 + 1) * 100) }

        let events = bcEvents + [yearZeroEvent] + adEvents

        let questions = WMFGamesDataController.makeWhichCameFirstQuestions(
            from: events,
            month: 5,
            day: 7,
            year: 2026,
            count: 5
        )

        XCTAssertEqual(questions.count, 5, "AD events alone should be enough to build all questions")

        let excludedTitles = Set(bcEvents.map { $0.text } + [yearZeroEvent.text])
        for question in questions {
            XCTAssertFalse(
                excludedTitles.contains(question.optionA.title),
                "BC/year-zero event leaked into optionA: \(question.optionA.title)"
            )
            XCTAssertFalse(
                excludedTitles.contains(question.optionB.title),
                "BC/year-zero event leaked into optionB: \(question.optionB.title)"
            )
        }
    }

    func testQuestionsAreDeterministicForSameDate() {
        let events = (1...30).map { makeEvent(text: "Event \(["Alpha","Beta","Gamma","Delta","Epsilon","Zeta","Eta","Theta","Iota","Kappa","Lambda","Mu","Nu","Xi","Omicron","Pi","Rho","Sigma","Tau","Upsilon","Phi","Chi","Psi","Omega","Ares","Zeus","Hera","Athena","Apollo","Hermes"][$0 - 1])", year: $0 * 50) }

        let first = WMFGamesDataController.makeWhichCameFirstQuestions(from: events, month: 5, day: 7, year: 2026, count: 5)
        let second = WMFGamesDataController.makeWhichCameFirstQuestions(from: events, month: 5, day: 7, year: 2026, count: 5)

        // Compare the unordered pair of titles per question — optionA/B assignment uses Bool.random()
        // so we can't compare positionally, but the paired events themselves must be identical.
        let firstPairs = first.map { Set([$0.optionA.title, $0.optionB.title]) }
        let secondPairs = second.map { Set([$0.optionA.title, $0.optionB.title]) }
        XCTAssertEqual(firstPairs, secondPairs, "Same date should always produce the same question pairings")
    }

    func testPoolFiltersEventsWithYearInText() {
        // Events whose text contains a standalone number should be excluded from the pool.
        let eventsWithYearInText = [
            makeEvent(text: "Something happened in 1492", year: 100),
            makeEvent(text: "An event occurred in 42 AD", year: 200),
            makeEvent(text: "Event from the year 800", year: 300)
        ]
        let cleanEventNames = ["Alpha","Beta","Gamma","Delta","Epsilon","Zeta","Eta","Theta","Iota","Kappa"]
        let cleanEvents = (0...9).map { makeEvent(text: "Clean event \(cleanEventNames[$0])", year: ($0 + 1) * 100 + 400) }

        let questions = WMFGamesDataController.makeWhichCameFirstQuestions(
            from: eventsWithYearInText + cleanEvents,
            month: 5,
            day: 7,
            year: 2026,
            count: 5
        )

        let filteredTitles = Set(eventsWithYearInText.map { $0.text })
        for question in questions {
            XCTAssertFalse(filteredTitles.contains(question.optionA.title), "Event with number in text leaked into optionA: \(question.optionA.title)")
            XCTAssertFalse(filteredTitles.contains(question.optionB.title), "Event with number in text leaked into optionB: \(question.optionB.title)")
        }
    }

    func testPoolFiltersEventsBeyondCurrentYear() {
        let pastEventNames = ["Alpha","Beta","Gamma","Delta","Epsilon","Zeta","Eta","Theta","Iota","Kappa"]
        let currentYearEvents = (0...9).map { makeEvent(text: "Past event \(pastEventNames[$0])", year: ($0 + 1) * 100) }
        let futureEvents = [
            makeEvent(text: "Future event Alpha", year: 2100),
            makeEvent(text: "Future event Beta", year: 2200)
        ]

        let questions = WMFGamesDataController.makeWhichCameFirstQuestions(
            from: currentYearEvents + futureEvents,
            month: 5,
            day: 7,
            year: 2026,
            count: 5
        )

        let futureTitles = Set(futureEvents.map { $0.text })
        for question in questions {
            XCTAssertFalse(futureTitles.contains(question.optionA.title), "Future event leaked into optionA: \(question.optionA.title)")
            XCTAssertFalse(futureTitles.contains(question.optionB.title), "Future event leaked into optionB: \(question.optionB.title)")
        }
    }

    func testPoolDeduplicatesByYear() {
        // Two events with the same year — only one should enter the pool, so both
        // questions must use distinct years for their paired options.
        let events = [
            makeEvent(text: "Event Alpha", year: 100),
            makeEvent(text: "Event Beta", year: 100),
            makeEvent(text: "Event Gamma", year: 200),
            makeEvent(text: "Event Delta", year: 300),
            makeEvent(text: "Event Epsilon", year: 400),
            makeEvent(text: "Event Zeta", year: 500),
            makeEvent(text: "Event Eta", year: 600),
            makeEvent(text: "Event Theta", year: 700),
            makeEvent(text: "Event Iota", year: 800),
            makeEvent(text: "Event Kappa", year: 900),
            makeEvent(text: "Event Lambda", year: 1000)
        ]

        let questions = WMFGamesDataController.makeWhichCameFirstQuestions(
            from: events,
            month: 5,
            day: 7,
            year: 2026,
            count: 5
        )

        // Collect every year used across all questions.
        var usedYears: [Int] = []
        for question in questions {
            let calendar = Calendar(identifier: .gregorian)
            let yearA = calendar.component(.year, from: question.optionA.date)
            let yearB = calendar.component(.year, from: question.optionB.date)
            usedYears.append(contentsOf: [yearA, yearB])
        }

        // After dedup, year 100 appears only once in the pool, so it can appear at most once.
        let year100Count = usedYears.filter { $0 == 100 }.count
        XCTAssertLessThanOrEqual(year100Count, 1, "Year 100 should appear at most once across all questions after year deduplication")
    }

    func testAllBCEventsProduceNoQuestions() {
        let bcEvents = (1...20).map { makeEvent(text: "BC Event \(["Alpha","Beta","Gamma","Delta","Epsilon","Zeta","Eta","Theta","Iota","Kappa","Lambda","Mu","Nu","Xi","Omicron","Pi","Rho","Sigma","Tau","Upsilon"][$0 - 1])", year: -$0 * 100) }

        let questions = WMFGamesDataController.makeWhichCameFirstQuestions(
            from: bcEvents,
            month: 5,
            day: 7,
            year: 2026,
            count: 5
        )

        XCTAssertTrue(questions.isEmpty, "A pool of only BC events should yield no questions")
    }

    // MARK: - submitWhichCameFirstAnswer Tests

    func testSubmitCorrectAnswerIncrementsScore() async throws {
        guard let dataController else { throw TestsError.missingDataController }

        let (gameState, _) = try await dataController.fetchOrStartWhichCameFirstDailySession(
            date: dateWithEnoughEvents,
            project: enProject,
            onThisDayDataController: onThisDayControllerWithEnoughEvents()
        )

        guard let firstQuestion = gameState.questions.first else {
            XCTFail("Expected at least one question")
            return
        }

        let sessionID = try await sessionIdentifier(for: dateWithEnoughEvents)
        let result = try await dataController.submitWhichCameFirstAnswer(
            sessionIdentifier: sessionID,
            questionIdentifier: firstQuestion.id,
            pickedOption: firstQuestion.correctAnswer
        )

        XCTAssertTrue(result.isCorrect)
        XCTAssertEqual(result.correctAnswer, firstQuestion.correctAnswer)

        let sessions = try await dataController.fetchWhichCameFirstSessions(project: enProject)
        XCTAssertEqual(sessions.first?.score, 1)
    }

    func testSubmitWrongAnswerDoesNotIncrementScore() async throws {
        guard let dataController else { throw TestsError.missingDataController }

        let (gameState, _) = try await dataController.fetchOrStartWhichCameFirstDailySession(
            date: dateWithEnoughEvents,
            project: enProject,
            onThisDayDataController: onThisDayControllerWithEnoughEvents()
        )

        guard let firstQuestion = gameState.questions.first else {
            XCTFail("Expected at least one question")
            return
        }

        let wrongAnswer = firstQuestion.correctAnswer == "A" ? "B" : "A"
        let sessionID = try await sessionIdentifier(for: dateWithEnoughEvents)
        let result = try await dataController.submitWhichCameFirstAnswer(
            sessionIdentifier: sessionID,
            questionIdentifier: firstQuestion.id,
            pickedOption: wrongAnswer
        )

        XCTAssertFalse(result.isCorrect)
        XCTAssertEqual(result.correctAnswer, firstQuestion.correctAnswer)

        let sessions = try await dataController.fetchWhichCameFirstSessions(project: enProject)
        XCTAssertEqual(sessions.first?.score, 0)
    }

    func testSubmitInvalidOptionThrows() async throws {
        guard let dataController else { throw TestsError.missingDataController }

        let (gameState, _) = try await dataController.fetchOrStartWhichCameFirstDailySession(
            date: dateWithEnoughEvents,
            project: enProject,
            onThisDayDataController: onThisDayControllerWithEnoughEvents()
        )

        guard let firstQuestion = gameState.questions.first else {
            XCTFail("Expected at least one question")
            return
        }

        let sessionID = try await sessionIdentifier(for: dateWithEnoughEvents)
        do {
            _ = try await dataController.submitWhichCameFirstAnswer(
                sessionIdentifier: sessionID,
                questionIdentifier: firstQuestion.id,
                pickedOption: "C"
            )
            XCTFail("Expected invalidPickedOption error")
        } catch WMFGamesDataController.CustomError.invalidPickedOption {
            // expected
        }
    }

    func testAnsweringAllQuestionsCompletesSession() async throws {
        guard let dataController else { throw TestsError.missingDataController }

        let (gameState, _) = try await dataController.fetchOrStartWhichCameFirstDailySession(
            date: dateWithEnoughEvents,
            project: enProject,
            onThisDayDataController: onThisDayControllerWithEnoughEvents()
        )

        XCTAssertEqual(gameState.questions.count, 5)
        let sessionID = try await sessionIdentifier(for: dateWithEnoughEvents)

        for question in gameState.questions {
            _ = try await dataController.submitWhichCameFirstAnswer(
                sessionIdentifier: sessionID,
                questionIdentifier: question.id,
                pickedOption: question.correctAnswer
            )
        }

        let sessions = try await dataController.fetchWhichCameFirstSessions(project: enProject)
        guard let session = sessions.first else {
            XCTFail("Expected at least one session")
            return
        }

        XCTAssertEqual(session.status, .completed)
        XCTAssertNotNil(session.completedDate)
        XCTAssertEqual(session.score, 5)
        XCTAssertEqual(session.currentQuestionIndex, 5)
    }

    func testSubmitAnswerUpdatesCurrentQuestionIndex() async throws {
        guard let dataController else { throw TestsError.missingDataController }

        let (gameState, _) = try await dataController.fetchOrStartWhichCameFirstDailySession(
            date: dateWithEnoughEvents,
            project: enProject,
            onThisDayDataController: onThisDayControllerWithEnoughEvents()
        )

        guard let firstQuestion = gameState.questions.first else {
            XCTFail("Expected at least one question")
            return
        }

        let sessionID = try await sessionIdentifier(for: dateWithEnoughEvents)
        _ = try await dataController.submitWhichCameFirstAnswer(
            sessionIdentifier: sessionID,
            questionIdentifier: firstQuestion.id,
            pickedOption: firstQuestion.correctAnswer
        )

        let sessions = try await dataController.fetchWhichCameFirstSessions(project: enProject)
        XCTAssertEqual(sessions.first?.currentQuestionIndex, 1)
    }

    // MARK: - fetchWhichCameFirstSessions Tests

    func testFetchSessionsReturnsSortedByDateDescending() async throws {
        guard let dataController else { throw TestsError.missingDataController }

        let earlierDate = "2026-05-06"
        let laterDate = "2026-05-07"

        _ = try await dataController.fetchOrStartWhichCameFirstDailySession(
            date: earlierDate,
            project: enProject,
            onThisDayDataController: onThisDayControllerWithEnoughEvents()
        )

        _ = try await dataController.fetchOrStartWhichCameFirstDailySession(
            date: laterDate,
            project: enProject,
            onThisDayDataController: onThisDayControllerWithEnoughEvents()
        )

        let sessions = try await dataController.fetchWhichCameFirstSessions(project: enProject)
        XCTAssertEqual(sessions.count, 2)
        XCTAssertEqual(sessions[0].dailyGameDate, laterDate)
        XCTAssertEqual(sessions[1].dailyGameDate, earlierDate)
    }

    func testFetchSessionsReturnsEmptyForNewStore() async throws {
        guard let dataController else { throw TestsError.missingDataController }

        let sessions = try await dataController.fetchWhichCameFirstSessions(project: enProject)
        XCTAssertTrue(sessions.isEmpty)
    }

    // MARK: - isWhichCameFirstDailySessionAvailable Tests

    func testIsAvailableReturnsTrueForExistingSession() async throws {
        guard let dataController else { throw TestsError.missingDataController }

        _ = try await dataController.fetchOrStartWhichCameFirstDailySession(
            date: dateWithEnoughEvents,
            project: enProject,
            onThisDayDataController: onThisDayControllerWithEnoughEvents()
        )

        let isAvailable = try await dataController.isWhichCameFirstDailySessionAvailable(
            date: dateWithEnoughEvents,
            project: enProject,
            onThisDayDataController: onThisDayControllerWithEnoughEvents()
        )

        XCTAssertTrue(isAvailable)
    }

    func testIsAvailableReturnsTrueWhenAPIHasEnoughEvents() async throws {
        guard let dataController else { throw TestsError.missingDataController }

        let isAvailable = try await dataController.isWhichCameFirstDailySessionAvailable(
            date: dateWithEnoughEvents,
            project: enProject,
            onThisDayDataController: onThisDayControllerWithEnoughEvents()
        )

        XCTAssertTrue(isAvailable)
    }

    func testIsAvailableReturnsFalseWhenAPIHasInsufficientEvents() async throws {
        guard let dataController else { throw TestsError.missingDataController }

        let isAvailable = try await dataController.isWhichCameFirstDailySessionAvailable(
            date: dateWithFewEvents,
            project: enProject,
            onThisDayDataController: onThisDayControllerWithFewEvents()
        )

        XCTAssertFalse(isAvailable)
    }

    // MARK: - fetchWhichCameFirstStats Tests

    func testStatsGamesPlayedCountsOnlyCompletedSessions() async throws {
        guard let dataController else { throw TestsError.missingDataController }

        // Start but do not complete a session
        _ = try await dataController.fetchOrStartWhichCameFirstDailySession(
            date: dateWithEnoughEvents,
            project: enProject,
            onThisDayDataController: onThisDayControllerWithEnoughEvents()
        )

        let stats = try await dataController.fetchWhichCameFirstStats(project: enProject)
        XCTAssertEqual(stats.gamesPlayed, 0)
    }

    func testStatsGamesPlayedIncrementsAfterCompletion() async throws {
        guard let dataController else { throw TestsError.missingDataController }

        try await completeAllQuestions(for: dateWithEnoughEvents)

        let stats = try await dataController.fetchWhichCameFirstStats(project: enProject)
        XCTAssertEqual(stats.gamesPlayed, 1)
    }

    func testStatsAverageScoreAfterPerfectGame() async throws {
        guard let dataController else { throw TestsError.missingDataController }

        try await completeAllQuestions(for: dateWithEnoughEvents)

        let stats = try await dataController.fetchWhichCameFirstStats(project: enProject)
        XCTAssertEqual(stats.averageScore, 5)
    }

    func testStatsBestStreakAfterOneGame() async throws {
        guard let dataController else { throw TestsError.missingDataController }

        try await completeAllQuestions(for: dateWithEnoughEvents)

        let stats = try await dataController.fetchWhichCameFirstStats(project: enProject)
        XCTAssertEqual(stats.bestStreak, 1)
    }

    func testStatsAreZeroWithNoSessions() async throws {
        guard let dataController else { throw TestsError.missingDataController }

        let stats = try await dataController.fetchWhichCameFirstStats(project: enProject)
        XCTAssertEqual(stats.gamesPlayed, 0)
        XCTAssertEqual(stats.currentStreak, 0)
        XCTAssertEqual(stats.bestStreak, 0)
        XCTAssertEqual(stats.averageScore, 0)
    }

    // MARK: - fetchWhichCameFirstDailyPreviewEvents Tests

    func testPreviewEventsReturnsTwoDistinctOptions() async throws {
        guard let dataController else { throw TestsError.missingDataController }

        let preview = try await dataController.fetchWhichCameFirstDailyPreviewEvents(
            date: dateWithEnoughEvents,
            project: enProject,
            onThisDayDataController: onThisDayControllerWithEnoughEvents()
        )

        XCTAssertNotNil(preview)
        XCTAssertNotEqual(preview?.optionA.date, preview?.optionB.date)
    }

    func testPreviewEventsReusesExistingSessionWithoutAPICall() async throws {
        guard let dataController else { throw TestsError.missingDataController }

        // Create a session first
        let (gameState, _) = try await dataController.fetchOrStartWhichCameFirstDailySession(
            date: dateWithEnoughEvents,
            project: enProject,
            onThisDayDataController: onThisDayControllerWithEnoughEvents()
        )

        guard let firstQuestion = gameState.questions.first else {
            XCTFail("Expected at least one question")
            return
        }

        // Preview should match the already-persisted first question
        let preview = try await dataController.fetchWhichCameFirstDailyPreviewEvents(
            date: dateWithEnoughEvents,
            project: enProject,
            onThisDayDataController: onThisDayControllerWithEnoughEvents()
        )

        XCTAssertEqual(preview?.optionA.title, firstQuestion.optionA.title)
        XCTAssertEqual(preview?.optionB.title, firstQuestion.optionB.title)
    }

    // MARK: - Helpers

    /// Fetches the identifier of the persisted session for a given date from Core Data.
    private func sessionIdentifier(for date: String) async throws -> UUID {
        guard let dataController else { throw TestsError.missingDataController }
        let sessions = try await dataController.fetchWhichCameFirstSessions(project: enProject)
        guard let session = sessions.first(where: { $0.dailyGameDate == date }) else {
            throw TestsError.sessionNotFound
        }
        return session.identifier
    }

    /// Starts a session for the given date and answers all questions correctly.
    @discardableResult
    private func completeAllQuestions(for date: String) async throws -> [WMFWhichCameFirstQuestion] {
        guard let dataController else { throw TestsError.missingDataController }

        let (gameState, _) = try await dataController.fetchOrStartWhichCameFirstDailySession(
            date: date,
            project: enProject,
            onThisDayDataController: onThisDayControllerWithEnoughEvents()
        )

        let sessionID = try await sessionIdentifier(for: date)
        for question in gameState.questions {
            _ = try await dataController.submitWhichCameFirstAnswer(
                sessionIdentifier: sessionID,
                questionIdentifier: question.id,
                pickedOption: question.correctAnswer
            )
        }

        return gameState.questions
    }

    // MARK: - Error

    enum TestsError: Error {
        case missingDataController
        case sessionNotFound
    }
}
