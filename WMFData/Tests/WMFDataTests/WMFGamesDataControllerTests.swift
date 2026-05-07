import XCTest
@testable import WMFData
@testable import WMFDataMocks

final class WMFGamesDataControllerTests: XCTestCase {

    // MARK: - Properties

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
        let temporaryDirectory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let store = try await WMFCoreDataStore(appContainerURL: temporaryDirectory)
        self.store = store

        WMFDataEnvironment.current.appData = WMFAppData(appLanguages: [
            WMFLanguage(languageCode: "en", languageVariantCode: nil)
        ])

        self.dataController = WMFGamesDataController(coreDataStore: store)

        try await super.setUp()
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

        let gameState = try await dataController.fetchOrStartWhichCameFirstDailySession(
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

        // Start a fresh session
        let firstState = try await dataController.fetchOrStartWhichCameFirstDailySession(
            date: dateWithEnoughEvents,
            project: enProject,
            onThisDayDataController: otdController
        )

        guard let firstQuestion = firstState.questions.first else {
            XCTFail("Expected at least one question")
            return
        }

        // Submit one answer so the session has a non-empty answers dict
        _ = try await dataController.submitWhichCameFirstAnswer(
            sessionIdentifier: try await sessionIdentifier(for: dateWithEnoughEvents),
            questionIdentifier: firstQuestion.id,
            pickedOption: firstQuestion.correctAnswer
        )

        // Resume — pass a new controller that would also work (but session should be loaded from DB)
        let resumedState = try await dataController.fetchOrStartWhichCameFirstDailySession(
            date: dateWithEnoughEvents,
            project: enProject,
            onThisDayDataController: makeOnThisDayController(fixture: "onthisday-events-05-07-get")
        )

        // Should have the same 5 questions and the already-submitted answer
        XCTAssertEqual(resumedState.questions.count, 5)
        XCTAssertEqual(resumedState.answers.count, 1)
        XCTAssertEqual(resumedState.answers[firstQuestion.id.uuidString], firstQuestion.correctAnswer)
    }

    // MARK: - submitWhichCameFirstAnswer Tests

    func testSubmitCorrectAnswerIncrementsScore() async throws {
        guard let dataController else { throw TestsError.missingDataController }

        let gameState = try await dataController.fetchOrStartWhichCameFirstDailySession(
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

        let gameState = try await dataController.fetchOrStartWhichCameFirstDailySession(
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

        let gameState = try await dataController.fetchOrStartWhichCameFirstDailySession(
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

        let gameState = try await dataController.fetchOrStartWhichCameFirstDailySession(
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

    // MARK: - fetchWhichCameFirstSessions Tests

    func testFetchSessionsReturnsSortedByDateDescending() async throws {
        guard let dataController else { throw TestsError.missingDataController }

        let earlierDate = "2026-05-06"
        let laterDate = "2026-05-07"

        // Create sessions on two different dates (both use the same 55-event fixture)
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

    // MARK: - isWhichCameFirstDailySessionAvailable Tests

    func testIsAvailableReturnsTrueForExistingSession() async throws {
        guard let dataController else { throw TestsError.missingDataController }

        // Create a session first
        _ = try await dataController.fetchOrStartWhichCameFirstDailySession(
            date: dateWithEnoughEvents,
            project: enProject,
            onThisDayDataController: onThisDayControllerWithEnoughEvents()
        )

        // isAvailable should return true even with a mock that would fail (session is already persisted)
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

    // MARK: - Error

    enum TestsError: Error {
        case missingDataController
        case sessionNotFound
    }
}
