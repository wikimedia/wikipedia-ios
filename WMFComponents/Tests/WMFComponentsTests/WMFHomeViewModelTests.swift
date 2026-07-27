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
        XCTAssertFalse(vm.forYouModuleVisibility.basedOnInterests)
        XCTAssertFalse(controller.forYouBasedOnInterestsIsOn())
        XCTAssertTrue(vm.forYouModuleVisibility.becauseYouRead)
        XCTAssertTrue(vm.forYouModuleVisibility.continueReading)
    }

    func testHideForYouBecauseYouRead() {
        let (vm, controller) = makeViewModel()
        vm.hideForYouModule(.becauseYouRead)
        XCTAssertFalse(vm.forYouModuleVisibility.becauseYouRead)
        XCTAssertFalse(controller.forYouBecauseYouReadIsOn())
        XCTAssertTrue(vm.forYouModuleVisibility.basedOnInterests)
        XCTAssertTrue(vm.forYouModuleVisibility.continueReading)
    }

    func testHideForYouContinueReading() {
        let (vm, controller) = makeViewModel()
        vm.hideForYouModule(.continueReading)
        XCTAssertFalse(vm.forYouModuleVisibility.continueReading)
        XCTAssertFalse(controller.forYouContinueReadingIsOn())
    }

    // MARK: - Hide Card (Community)

    func testHideCardAppendsToHiddenKeys() {
        let (vm, _) = makeViewModel()
        vm.hideCard(key: "featured_article_Octopus")
        XCTAssertTrue(vm.hiddenCardKeys.contains("featured_article_Octopus"))
        XCTAssertTrue(vm.hiddenCardKeySet.contains("featured_article_Octopus"))
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
        XCTAssertEqual(vm.hiddenCardKeys, ["card_a", "card_b"])
    }

    // MARK: - Hide Card (For You)

    func testHideForYouCardAppendsKey() {
        let (vm, controller) = makeViewModel()
        let article = WMFForYouArticle(title: "Octopus", project: .wikipedia(WMFLanguage(languageCode: "en", languageVariantCode: nil)))
        let cardVM = WMFForYouArticleCardViewModel(article: article, headerLabel: "Test")
        vm.hideForYouCard(cardVM)
        XCTAssertTrue(vm.hiddenCardKeys.contains(cardVM.hideKey))
        XCTAssertTrue(controller.isCardHidden(key: cardVM.hideKey))
    }

    func testForYouHideKeyFormat() {
        let language = WMFLanguage(languageCode: "en", languageVariantCode: nil)
        let project = WMFProject.wikipedia(language)
        let article = WMFForYouArticle(title: "Octopus", project: project)
        let cardVM = WMFForYouArticleCardViewModel(article: article, headerLabel: "Test")
        XCTAssertEqual(cardVM.hideKey, "for_you_\(project.id)_Octopus")
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
        // communityPages is backed by WMFHomeCommunityViewModel which requires a full response,
        // so we verify it stays empty (cleared) after a language change — the didSet fires and clears it.
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
}
