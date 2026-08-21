import XCTest
import UIKit
import WMFDataTestSupport
@testable import WMFComponents
@testable import WMFData
import WMFDataMocks

@MainActor
final class WMFHomeViewModelTests: XCTestCase {

    private let fixture = WMFDataTestFixture()

    /// Takes the Core Data store away, so that a fetch stops immediately. Thus a test that must not
    /// use the network gets an exact time.
    private func removeCoreDataStore() async {
        WMFDataEnvironment.current.coreDataStore = nil
    }

    private func makeViewModel() -> (WMFHomeViewModel, WMFHomeDataController) {
        let controller = WMFHomeDataController(userDefaultsStore: WMFMockKeyValueStore())
        let vm = WMFHomeViewModel(dataController: controller, logDidTapLanguagePicker: {_ in })
        return (vm, controller)
    }

    private func makeForYouCardViewModel() -> WMFForYouArticleCardViewModel {
        let article = WMFForYouArticle(title: "Octopus", project: .wikipedia(WMFLanguage(languageCode: "en", languageVariantCode: nil)))
        let header = WMFForYouHeaderLabel(format: "Test %1$@", highlight: "")
        return WMFForYouArticleCardViewModel(article: article, headerLabel: header, module: .continueReading)
    }

    // MARK: - Hide Community Module

    func testHideCommunityFeaturedArticle() {
        let (vm, controller) = makeViewModel()
        vm.hideModule(.featuredArticle)
        XCTAssertFalse(vm.communityModuleVisibility.featuredArticle)
        XCTAssertFalse(controller.communityFeaturedArticleIsOn())
        XCTAssertTrue(vm.communityModuleVisibility.topRead)
        XCTAssertTrue(vm.communityModuleVisibility.inTheNews)
        XCTAssertTrue(vm.communityModuleVisibility.onThisDay)
        XCTAssertTrue(vm.communityModuleVisibility.pictureOfDay)
    }

    func testHideCommunityTopRead() {
        let (vm, controller) = makeViewModel()
        vm.hideModule(.topRead)
        XCTAssertFalse(vm.communityModuleVisibility.topRead)
        XCTAssertFalse(controller.communityTopReadIsOn())
        XCTAssertTrue(vm.communityModuleVisibility.featuredArticle)
    }

    func testHideCommunityInTheNews() {
        let (vm, controller) = makeViewModel()
        vm.hideModule(.inTheNews)
        XCTAssertFalse(vm.communityModuleVisibility.inTheNews)
        XCTAssertFalse(controller.communityInTheNewsIsOn())
    }

    func testHideCommunityOnThisDay() {
        let (vm, controller) = makeViewModel()
        vm.hideModule(.onThisDay)
        XCTAssertFalse(vm.communityModuleVisibility.onThisDay)
        XCTAssertFalse(controller.communityOnThisDayIsOn())
    }

    func testHideCommunityPictureOfDay() {
        let (vm, controller) = makeViewModel()
        vm.hideModule(.pictureOfDay)
        XCTAssertFalse(vm.communityModuleVisibility.pictureOfDay)
        XCTAssertFalse(controller.communityPictureOfTheDayIsOn())
    }

    // MARK: - Hide For You Module

    func testHideForYouBasedOnInterests() {
        let (vm, controller) = makeViewModel()
        vm.hideForYouModule(.basedOnInterests)
        XCTAssertFalse(controller.forYouBasedOnInterestsIsOn())
        XCTAssertTrue(controller.forYouBecauseYouReadIsOn())
        XCTAssertTrue(controller.forYouContinueReadingIsOn())
    }

    func testHideForYouBecauseYouRead() {
        let (vm, controller) = makeViewModel()
        vm.hideForYouModule(.becauseYouRead)
        XCTAssertFalse(controller.forYouBecauseYouReadIsOn())
        XCTAssertTrue(controller.forYouBasedOnInterestsIsOn())
        XCTAssertTrue(controller.forYouContinueReadingIsOn())
    }

    func testHideForYouContinueReading() {
        let (vm, controller) = makeViewModel()
        vm.hideForYouModule(.continueReading)
        XCTAssertFalse(controller.forYouContinueReadingIsOn())
    }

    func testHideForYouModuleUpdatesForYouViewModelVisibility() {
        let (vm, _) = makeViewModel()
        vm.forYouViewModel = WMFForYouViewModel(response: WMFForYouResponse(
            interestTopicRandomArticles: [],
            interestPageRelatedArticles: [],
            becauseYouReadArticles: nil,
            continueReadingArticles: nil
        ))
        vm.hideForYouModule(.basedOnInterests)
        XCTAssertFalse(vm.forYouViewModel?.moduleVisibility.basedOnInterests ?? true)
    }

    // MARK: - Hide Card (Community)

    func testHideCardAppendsToHiddenKeys() {
        let (vm, _) = makeViewModel()
        vm.hideCard(key: "featured_article_Octopus")
        XCTAssertTrue(vm.hiddenCardKeys.contains("featured_article_Octopus"))
    }

    func testHideCardPersistsViaDataController() {
        let (vm, controller) = makeViewModel()
        vm.hideCard(key: "featured_article_Octopus")
        XCTAssertTrue(controller.isCardHidden(key: "featured_article_Octopus"))
    }

    func testHideMultipleCardsAccumulates() {
        let (vm, _) = makeViewModel()
        vm.hideCard(key: "card_a")
        vm.hideCard(key: "card_b")
        XCTAssertTrue(vm.hiddenCardKeys.contains("card_a"))
        XCTAssertTrue(vm.hiddenCardKeys.contains("card_b"))
        XCTAssertEqual(vm.hiddenCardKeys.count, 2)
    }

    // MARK: - Hide Card (For You)

    func testHideForYouCardAppendsKey() {
        let (vm, controller) = makeViewModel()
        let cardVM = makeForYouCardViewModel()
        vm.hideForYouCard(cardVM)
        XCTAssertTrue(vm.hiddenCardKeys.contains(cardVM.cardUniqueKey))
        XCTAssertTrue(controller.isCardHidden(key: cardVM.cardUniqueKey))
    }

    func testForYouHideKeyFormat() {
        let language = WMFLanguage(languageCode: "en", languageVariantCode: nil)
        let project = WMFProject.wikipedia(language)
        let article = WMFForYouArticle(title: "Octopus", project: project)
        let header = WMFForYouHeaderLabel(format: "Test %1$@", highlight: "")
        let cardVM = WMFForYouArticleCardViewModel(article: article, headerLabel: header, module: .basedOnInterests)
        XCTAssertEqual(cardVM.cardUniqueKey, "for_you_\(project.id)_Octopus")
    }

    func testHidingACardReachesTheForYouFeed() {
        let (vm, _) = makeViewModel()
        vm.forYouViewModel = WMFForYouViewModel(response: WMFForYouResponse(
            interestTopicRandomArticles: [],
            interestPageRelatedArticles: [],
            becauseYouReadArticles: nil,
            continueReadingArticles: nil
        ))

        vm.hideCard(key: "featured_article_Octopus")

        XCTAssertTrue(vm.forYouViewModel?.hiddenCardKeys.contains("featured_article_Octopus") ?? false,
                      "The For You view model mirrors the hidden keys, and its view reads from that mirror")
    }

    func testAForYouFeedAttachedLaterStartsFromTheHiddenKeysAlreadySet() {
        let (vm, _) = makeViewModel()
        vm.hideCard(key: "card_hidden_before_the_feed_loaded")

        vm.forYouViewModel = WMFForYouViewModel(response: WMFForYouResponse(
            interestTopicRandomArticles: [],
            interestPageRelatedArticles: [],
            becauseYouReadArticles: nil,
            continueReadingArticles: nil
        ))

        XCTAssertTrue(vm.forYouViewModel?.hiddenCardKeys.contains("card_hidden_before_the_feed_loaded") ?? false,
                      "A feed that loads after a card was hidden must not show it again")
    }

    // MARK: - Embedded Community Content

    func testEmbeddedCommunityViewControllerSkipsCommunityFeedLoad() {
        let (vm, _) = makeViewModel()
        vm.makeEmbeddedCommunityViewController = { UIViewController() }
        vm.selectedLanguage = WMFLanguage(languageCode: "en", languageVariantCode: nil)

        vm.loadCommunityFeedIfNeeded()

        XCTAssertFalse(vm.isLoadingCommunity)
        XCTAssertTrue(vm.communityPages.isEmpty)
    }

    // MARK: - Language Picker Visibility

    func testLanguagePickerHiddenOnCommunityTabWithEmbeddedContent() {
        let (vm, _) = makeViewModel()
        vm.makeEmbeddedCommunityViewController = { UIViewController() }
        vm.selectedTab = .community
        XCTAssertFalse(vm.shouldShowLanguagePicker)
    }

    func testLanguagePickerShownOnForYouTabWithEmbeddedContent() {
        let (vm, _) = makeViewModel()
        vm.makeEmbeddedCommunityViewController = { UIViewController() }
        vm.selectedTab = .forYou
        XCTAssertTrue(vm.shouldShowLanguagePicker)
    }

    func testLanguagePickerShownOnCommunityTabWithoutEmbeddedContent() {
        let (vm, _) = makeViewModel()
        vm.selectedTab = .community
        XCTAssertTrue(vm.shouldShowLanguagePicker)
    }

    // MARK: - Selected Language Clears Feeds

    func testChangingLanguageResetsTheForYouFeed() {
        let (vm, _) = makeViewModel()
        let english = WMFLanguage(languageCode: "en", languageVariantCode: nil)
        let spanish = WMFLanguage(languageCode: "es", languageVariantCode: nil)

        vm.selectedLanguage = english
        vm.forYouViewModel = WMFForYouViewModel(response: WMFForYouResponse(
            interestTopicRandomArticles: [],
            interestPageRelatedArticles: [],
            becauseYouReadArticles: nil,
            continueReadingArticles: nil
        ))
        vm.forYouFeedError = URLError(.notConnectedToInternet)
        XCTAssertNotNil(vm.forYouViewModel)

        vm.selectedLanguage = spanish

        XCTAssertNil(vm.forYouViewModel)
        XCTAssertNil(vm.forYouFeedError, "The error described the previous language's fetch, so it must not stay on screen while the new one is loaded")
        XCTAssertTrue(vm.communityPages.isEmpty)
    }

    func testChangingLanguageClearsCommunityFeed() {
        let (vm, _) = makeViewModel()
        let english = WMFLanguage(languageCode: "en", languageVariantCode: nil)
        let spanish = WMFLanguage(languageCode: "es", languageVariantCode: nil)

        vm.selectedLanguage = english
        vm.selectedLanguage = spanish

        XCTAssertTrue(vm.communityPages.isEmpty)
    }

    func testSettingSameLanguageDoesNotClearForYouFeed() {
        let (vm, _) = makeViewModel()
        let english = WMFLanguage(languageCode: "en", languageVariantCode: nil)
        vm.selectedLanguage = english
        vm.forYouViewModel = WMFForYouViewModel(response: WMFForYouResponse(
            interestTopicRandomArticles: [],
            interestPageRelatedArticles: [],
            becauseYouReadArticles: nil,
            continueReadingArticles: nil
        ))

        vm.selectedLanguage = english

        XCTAssertNotNil(vm.forYouViewModel)
    }

    // MARK: - Daily refresh

    private func makeForYouViewModel() -> WMFForYouViewModel {
        WMFForYouViewModel(response: WMFForYouResponse(
            interestTopicRandomArticles: [],
            interestPageRelatedArticles: [],
            becauseYouReadArticles: nil,
            continueReadingArticles: nil
        ))
    }

    /// Noon of today, which is always in the same calendar day as the moment a feed loads in a test.
    private var laterToday: Date {
        Calendar.current.startOfDay(for: Date()).addingTimeInterval(12 * 60 * 60)
    }

    private var tomorrow: Date {
        Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
    }

    func testFeedIsDiscardedWhenTheDayChanges() {
        let (vm, _) = makeViewModel()
        vm.forYouViewModel = makeForYouViewModel()

        vm.refreshFeedsIfDayChanged(now: tomorrow)

        XCTAssertNil(vm.forYouViewModel)
    }

    func testFeedIsKeptWithinTheSameDay() {
        let (vm, _) = makeViewModel()
        vm.forYouViewModel = makeForYouViewModel()

        vm.refreshFeedsIfDayChanged(now: laterToday)

        XCTAssertNotNil(vm.forYouViewModel)
    }

    func testDayChangeDoesNothingWhenNoFeedIsLoaded() {
        let (vm, _) = makeViewModel()

        vm.refreshFeedsIfDayChanged(now: tomorrow)

        XCTAssertNil(vm.forYouViewModel)
        XCTAssertFalse(vm.isLoadingForYou)
        XCTAssertFalse(vm.isLoadingCommunity)
    }

    // MARK: - Refresh indicator

    func testRefreshIndicatorStartsOff() {
        let (vm, _) = makeViewModel()

        XCTAssertFalse(vm.isRefreshingForYou)
    }

    /// The indicator must still be on when the refresh returns, and must go off after the minimum
    /// time. A refresh replaces the For You view model, which removes the view that started the
    /// refresh, so the indicator must not depend on the task of that view.
    ///
    /// With no Core Data store the fetch fails immediately, which makes the timing exact and keeps
    /// the test off the network. The fixture holds the global state and puts the environment back,
    /// so this change cannot reach the other tests.
    func testRefreshIndicatorStaysOnAfterTheRefreshReturns() async {
        await fixture.withConfiguredEnvironment(configure: removeCoreDataStore) {
            let (vm, _) = makeViewModel()
            vm.selectedLanguage = WMFLanguage(languageCode: "en", languageVariantCode: nil)

            let start = Date()
            await vm.refreshForYouFeed(minimumIndicatorDuration: 0.2)

            XCTAssertTrue(vm.isRefreshingForYou)

            await vm.refreshIndicatorTask?.value

            XCTAssertGreaterThanOrEqual(Date().timeIntervalSince(start), 0.2)
            XCTAssertFalse(vm.isRefreshingForYou)
        }
    }

    /// With no language there is nothing to fetch, so the indicator must not appear at all.
    func testRefreshWithNoLanguageDoesNotShowTheIndicator() async {
        let (vm, _) = makeViewModel()
        vm.selectedLanguage = nil

        await vm.refreshForYouFeed(minimumIndicatorDuration: 0.2)

        XCTAssertFalse(vm.isRefreshingForYou)
    }

    func testDayChangeClearsAnEarlierError() {
        let (vm, _) = makeViewModel()
        vm.forYouViewModel = makeForYouViewModel()
        vm.forYouFeedError = NSError(domain: "test", code: 1)

        vm.refreshFeedsIfDayChanged(now: tomorrow)

        XCTAssertNil(vm.forYouFeedError)
    }

}
