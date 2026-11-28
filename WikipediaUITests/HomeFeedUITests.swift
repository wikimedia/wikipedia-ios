import XCTest

/// Tests for the parts of the Home tab that both feeds share: the segments, the language picker, and
/// the "Enable Home Phase 2" developer setting that picks the Community feed.
final class HomeFeedUITests: XCTestCase {

    func testSegmentsSwitchBetweenForYouAndCommunitySmoke() throws {
        let home = launchHome(homePhase: .phase2)

        home.openCommunity()
            .assertFeedVisible()
        home.openForYou()
            .assertFeedVisible()
        home.assertSegmentSelected(.forYou)
            .openCommunity()
            .assertFeedVisible()
    }

    func testPhase1CommunitySegmentShowsEmbeddedExploreFeedSmoke() throws {
        launchHome(homePhase: .phase1)
            .selectSegment(.community)
            .assertEmbeddedExploreFeedVisible()
            .assertNativeCommunityFeedAbsent()
            .assertLanguagePickerAbsent()
    }

    func testPhase2CommunitySegmentShowsNativeFeed() throws {
        let home = launchHome(homePhase: .phase2)

        home.openCommunity()
            .assertFeedVisible()
        home.assertLanguagePickerVisible()
    }

    func testPhase2CanBeTurnedOffAgain() throws {
        launchHome(homePhase: .phase2)
            .openCommunity()
            .assertFeedVisible()

        launchHome(homePhase: .phase1)
            .selectSegment(.community)
            .assertEmbeddedExploreFeedVisible()
            .assertNativeCommunityFeedAbsent()
    }

    func testForYouSegmentShowsLanguagePickerInPhase1() throws {
        launchHome(homePhase: .phase1)
            .selectSegment(.forYou)
            .assertLanguagePickerVisible()
    }

    func testLanguagePickerListsLanguagesAndOpensManageLanguages() throws {
        launchHome(homePhase: .phase2)
            .selectSegment(.community)
            .openLanguagePicker()
            .tapManageLanguages()
    }

    // MARK: - Helpers

    private func launchHome(
        homePhase: UITestConfiguration.HomePhase,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> HomeRobot {
        launchWikipediaAppRobot(
            onboardingState: .completed,
            readingListsSeed: .empty,
            homePhase: homePhase,
            homeFeedState: .oneInterest
        )
        .home
        .assertVisible(file: file, line: line)
    }
}
