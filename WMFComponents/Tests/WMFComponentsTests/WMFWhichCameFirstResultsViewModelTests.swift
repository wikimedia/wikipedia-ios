import XCTest
import Combine
@testable import WMFComponents
@testable import WMFData
import WMFDataMocks

@MainActor
final class WMFWhichCameFirstResultsViewModelTests: XCTestCase {

    // MARK: - Fixtures

    var enLanguage: WMFLanguage {
        WMFLanguage(languageCode: "en", languageVariantCode: nil)
    }

    var enProject: WMFProject {
        .wikipedia(enLanguage)
    }

    func makeViewModel(
        score: Int = 3,
        totalQuestions: Int = 5,
        isLoggedIn: Bool = false,
        gamesPlayed: Int? = nil,
        currentStreak: Int? = nil,
        bestStreak: Int? = nil,
        averageScore: Double? = nil
    ) -> WMFWhichCameFirstResultsViewModel {
        WMFWhichCameFirstResultsViewModel(
            score: score,
            totalQuestions: totalQuestions,
            isLoggedIn: isLoggedIn,
            project: enProject,
            gamesPlayed: gamesPlayed,
            currentStreak: currentStreak,
            bestStreak: bestStreak,
            averageScore: averageScore
        )
    }

    // MARK: - Initial State

    func testInitialScoreIsSet() {
        let viewModel = makeViewModel(score: 4)
        XCTAssertEqual(viewModel.score, 4)
    }

    func testInitialTotalQuestionsIsSet() {
        let viewModel = makeViewModel(totalQuestions: 5)
        XCTAssertEqual(viewModel.totalQuestions, 5)
    }

    func testInitialIsLoggedInFalse() {
        let viewModel = makeViewModel(isLoggedIn: false)
        XCTAssertFalse(viewModel.isLoggedIn)
    }

    func testInitialIsLoggedInTrue() {
        let viewModel = makeViewModel(isLoggedIn: true)
        XCTAssertTrue(viewModel.isLoggedIn)
    }

    func testInitialGamesPlayedIsNilWhenNotProvided() {
        let viewModel = makeViewModel()
        XCTAssertNil(viewModel.gamesPlayed)
    }

    func testInitialGamesPlayedIsSetWhenProvided() {
        let viewModel = makeViewModel(gamesPlayed: 10)
        XCTAssertEqual(viewModel.gamesPlayed, 10)
    }

    func testInitialCurrentStreakIsNilWhenNotProvided() {
        let viewModel = makeViewModel()
        XCTAssertNil(viewModel.currentStreak)
    }

    func testInitialCurrentStreakIsSetWhenProvided() {
        let viewModel = makeViewModel(currentStreak: 5)
        XCTAssertEqual(viewModel.currentStreak, 5)
    }

    func testInitialBestStreakIsNilWhenNotProvided() {
        let viewModel = makeViewModel()
        XCTAssertNil(viewModel.bestStreak)
    }

    func testInitialBestStreakIsSetWhenProvided() {
        let viewModel = makeViewModel(bestStreak: 12)
        XCTAssertEqual(viewModel.bestStreak, 12)
    }

    func testInitialAverageScoreIsNilWhenNotProvided() {
        let viewModel = makeViewModel()
        XCTAssertNil(viewModel.averageScore)
    }

    func testInitialAverageScoreIsSetWhenProvided() {
        let viewModel = makeViewModel(averageScore: 3)
        XCTAssertEqual(viewModel.averageScore, 3)
    }

    func testNextGameCountdownStringIsNotEmpty() {
        let viewModel = makeViewModel()
        XCTAssertFalse(viewModel.nextGameCountdownString.isEmpty)
    }

    func testNextGameCountdownStringMatchesHHMMSSFormat() {
        let viewModel = makeViewModel()
        let parts = viewModel.nextGameCountdownString.split(separator: ":")
        XCTAssertEqual(parts.count, 3)
        XCTAssertEqual(parts[0].count, 2)
        XCTAssertEqual(parts[1].count, 2)
        XCTAssertEqual(parts[2].count, 2)
    }

    // MARK: - Published Property Mutations

    func testIsLoggedInCanBeUpdated() {
        let viewModel = makeViewModel(isLoggedIn: false)
        viewModel.isLoggedIn = true
        XCTAssertTrue(viewModel.isLoggedIn)
    }

    func testScoreCanBeUpdated() {
        let viewModel = makeViewModel(score: 2)
        viewModel.score = 5
        XCTAssertEqual(viewModel.score, 5)
    }

    func testGamesPlayedCanBeUpdated() {
        let viewModel = makeViewModel()
        viewModel.gamesPlayed = 7
        XCTAssertEqual(viewModel.gamesPlayed, 7)
    }

    func testCurrentStreakCanBeUpdated() {
        let viewModel = makeViewModel()
        viewModel.currentStreak = 3
        XCTAssertEqual(viewModel.currentStreak, 3)
    }

    func testBestStreakCanBeUpdated() {
        let viewModel = makeViewModel()
        viewModel.bestStreak = 9
        XCTAssertEqual(viewModel.bestStreak, 9)
    }

    func testAverageScoreCanBeUpdated() {
        let viewModel = makeViewModel()
        viewModel.averageScore = 4
        XCTAssertEqual(viewModel.averageScore, 4)
    }

    // MARK: - Callbacks

    func testShareScoreCallbackIsCalled() {
        var called = false
        let viewModel = WMFWhichCameFirstResultsViewModel(
            score: 3,
            totalQuestions: 5,
            isLoggedIn: false,
            project: enProject,
            shareScore: { called = true }
        )
        viewModel.shareScore?()
        XCTAssertTrue(called)
    }

    func testOnLogInCallbackIsCalled() {
        var called = false
        let viewModel = WMFWhichCameFirstResultsViewModel(
            score: 3,
            totalQuestions: 5,
            isLoggedIn: false,
            project: enProject,
            onLogIn: { called = true }
        )
        viewModel.onLogIn?()
        XCTAssertTrue(called)
    }

    func testShareScoreIsNilWhenNotProvided() {
        let viewModel = makeViewModel()
        XCTAssertNil(viewModel.shareScore)
    }

    func testOnLogInIsNilWhenNotProvided() {
        let viewModel = makeViewModel()
        XCTAssertNil(viewModel.onLogIn)
    }

    // MARK: - LocalizedStrings: scoreLabel

    func testScoreLabelFormatsCorrectly() {
        let strings = WMFWhichCameFirstResultsViewModel.LocalizedStrings()
        let label = strings.scoreLabel(4, of: 5)
        XCTAssertTrue(label.contains("4"))
        XCTAssertTrue(label.contains("5"))
    }

    func testScoreLabelZeroScore() {
        let strings = WMFWhichCameFirstResultsViewModel.LocalizedStrings()
        let label = strings.scoreLabel(0, of: 5)
        XCTAssertTrue(label.contains("0"))
        XCTAssertTrue(label.contains("5"))
    }

    func testScoreLabelPerfectScore() {
        let strings = WMFWhichCameFirstResultsViewModel.LocalizedStrings()
        let label = strings.scoreLabel(5, of: 5)
        XCTAssertTrue(label.contains("5"))
    }

    // MARK: - LocalizedStrings: countdownLabel

    func testCountdownLabelContainsCountdownString() {
        let strings = WMFWhichCameFirstResultsViewModel.LocalizedStrings()
        let label = strings.countdownLabel(from: "01:23:45")
        XCTAssertTrue(label.contains("01:23:45"))
    }

    func testCountdownLabelWithZeroTime() {
        let strings = WMFWhichCameFirstResultsViewModel.LocalizedStrings()
        let label = strings.countdownLabel(from: "00:00:00")
        XCTAssertTrue(label.contains("00:00:00"))
    }
}
