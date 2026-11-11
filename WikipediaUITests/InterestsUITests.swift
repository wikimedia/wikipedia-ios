import XCTest

/// Tests for the interests selection screen, which appears as a step in app onboarding and
/// under Settings > Home feed > What's driving your feed > Your interests.
final class InterestsUITests: XCTestCase {

    // MARK: - Onboarding

    func testOnboardingInterestsShowsHeaderAndArticleGrid() throws {
        openOnboardingInterests()
            .assertArticleCardsVisible()
            .assertNothingSelected()
    }

    func testOnboardingInterestsTappingACardSelectsIt() throws {
        openOnboardingInterests()
            .assertArticleCardsVisible()
            .tapArticleCard(at: 0)
            .assertCardIsSelected(at: 0)
            .assertSelectedCount(1)
    }

    func testOnboardingInterestsTappingASelectedCardDeselectsIt() throws {
        openOnboardingInterests()
            .assertArticleCardsVisible()
            .tapArticleCard(at: 0)
            .assertSelectedCount(1)
            .tapArticleCard(at: 0)
            .assertNothingSelected()
    }

    func testOnboardingInterestsSelectionCountTracksEveryCard() throws {
        openOnboardingInterests()
            .assertArticleCardsVisible()
            .tapArticleCard(at: 0)
            .tapArticleCard(at: 1)
            .assertSelectedCount(2)
            .assertSelectedCardCount(2)
    }

    func testOnboardingInterestsDeselectAllClearsSelections() throws {
        openOnboardingInterests()
            .assertArticleCardsVisible()
            .tapArticleCard(at: 0)
            .tapArticleCard(at: 1)
            .assertSelectedCount(2)
            .tapDeselectAll()
            .assertNothingSelected()
    }

    func testOnboardingInterestsSearchAddsSelectedArticleAtTop() throws {
        openOnboardingInterests()
            .assertArticleCardsVisible()
            .searchInterests(for: "Einstein")
            .assertSearchResultsVisible()
            .addFirstSearchResult()
            .assertSelectedCount(1)
            .assertCardIsSelected(at: 0)
    }

    // MARK: - Settings

    func testSettingsOpensInterestsScreen() throws {
        openSettingsInterests()
            .assertArticleCardsVisible()
    }

    func testSettingsInterestsSelectionIsKeptWhenReopened() throws {
        let settings = openSettings()

        settings
            .openYourInterests()
            .clearExistingSelections()
            .searchInterests(for: "Einstein")
            .addFirstSearchResult()
            .assertSelectedCount(1)

        settings
            .goBackToWhatsDriving(isRightToLeft: uiTestConfiguration.isRightToLeft)
            .openYourInterests()
            .assertSelectedCount(1)
            .assertCardIsSelected(at: 0)
    }

    func testSettingsInterestsDeselectAllClearsSelections() throws {
        openSettings()
            .openYourInterests()
            .clearExistingSelections()
            .tapArticleCard(at: 0)
            .tapArticleCard(at: 1)
            .assertSelectedCount(2)
            .tapDeselectAll()
            .assertNothingSelected()
    }

    // MARK: - Helpers

    private func openOnboardingInterests(file: StaticString = #filePath, line: UInt = #line) -> InterestsRobot {
        launchWikipediaAppRobot(onboardingState: .notCompleted)
            .onboarding
            .advance(to: .interests, file: file, line: line)
            .interests(file: file, line: line)
    }

    private func openSettings(file: StaticString = #filePath, line: UInt = #line) -> SettingsRobot {
        launchWikipediaAppRobot(onboardingState: .completed)
            .home
            .assertVisible(file: file, line: line)
            .openProfile(file: file, line: line)
            .openSettings(file: file, line: line)
            .openHomeFeedSettings(file: file, line: line)
            .openWhatsDriving(file: file, line: line)
    }

    private func openSettingsInterests(file: StaticString = #filePath, line: UInt = #line) -> InterestsRobot {
        openSettings(file: file, line: line).openYourInterests(file: file, line: line)
    }
}
