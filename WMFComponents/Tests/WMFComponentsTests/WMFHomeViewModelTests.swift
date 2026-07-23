import XCTest
import UIKit
@testable import WMFComponents
@testable import WMFData
import WMFDataMocks

@MainActor
final class WMFHomeViewModelTests: XCTestCase {

    private func makeViewModel() -> (WMFHomeViewModel, WMFHomeDataController) {
        let controller = WMFHomeDataController(userDefaultsStore: WMFMockKeyValueStore())
        let vm = WMFHomeViewModel(dataController: controller)
        return (vm, controller)
    }

    private func makeForYouCardViewModel() -> WMFForYouArticleCardViewModel {
        let article = WMFForYouArticle(title: "Octopus", project: .wikipedia(WMFLanguage(languageCode: "en", languageVariantCode: nil)))
        let header = WMFForYouHeaderLabel(prefix: "Test", boldSuffix: "")
        return WMFForYouArticleCardViewModel(article: article, headerLabel: header)
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
        XCTAssertTrue(vm.hiddenCardKeys.contains(cardVM.hideKey))
        XCTAssertTrue(controller.isCardHidden(key: cardVM.hideKey))
    }

    func testForYouHideKeyFormat() {
        let language = WMFLanguage(languageCode: "en", languageVariantCode: nil)
        let project = WMFProject.wikipedia(language)
        let article = WMFForYouArticle(title: "Octopus", project: project)
        let header = WMFForYouHeaderLabel(prefix: "Test", boldSuffix: "")
        let cardVM = WMFForYouArticleCardViewModel(article: article, headerLabel: header)
        XCTAssertEqual(cardVM.hideKey, "for_you_\(project.id)_Octopus")
    }

    func testHideForYouCardIdempotent() {
        let (vm, _) = makeViewModel()
        let cardVM = makeForYouCardViewModel()
        vm.hideForYouCard(cardVM)
        vm.hideForYouCard(cardVM)
        XCTAssertEqual(vm.hiddenCardKeys.count, 1)
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

    func testChangingLanguageClearsForYouFeed() {
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
        XCTAssertNotNil(vm.forYouViewModel)

        vm.selectedLanguage = spanish

        XCTAssertNil(vm.forYouViewModel)
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

    func testChangingLanguageClearsForYouFeedError() {
        let (vm, _) = makeViewModel()
        let english = WMFLanguage(languageCode: "en", languageVariantCode: nil)
        let spanish = WMFLanguage(languageCode: "es", languageVariantCode: nil)

        vm.selectedLanguage = english
        vm.forYouFeedError = URLError(.notConnectedToInternet)
        XCTAssertNotNil(vm.forYouFeedError)

        vm.selectedLanguage = spanish

        XCTAssertNil(vm.forYouFeedError)
    }
}
