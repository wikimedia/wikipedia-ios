import XCTest
import WMFDataTestSupport
import UIKit
@testable import WMFComponents
@testable import WMFData
import WMFDataMocks

@MainActor
final class WMFHomeViewModelTests: XCTestCase {

    private let fixture = WMFDataTestFixture()

    private func makeViewModel() -> (WMFHomeViewModel, WMFHomeDataController) {
        let controller = WMFHomeDataController(userDefaultsStore: WMFMockKeyValueStore())
        let vm = WMFHomeViewModel(dataController: controller)
        return (vm, controller)
    }

    private func makeForYouCardViewModel() -> WMFForYouArticleCardViewModel {
        let article = WMFForYouArticle(title: "Octopus", project: .wikipedia(WMFLanguage(languageCode: "en", languageVariantCode: nil)))
        let header = WMFForYouHeaderLabel(format: "Test %1$@", highlight: "")
        return WMFForYouArticleCardViewModel(article: article, headerLabel: header)
    }

    private func makeForYouViewModel() -> WMFForYouViewModel {
        WMFForYouViewModel(response: WMFForYouResponse(
            interestTopicRandomArticles: [],
            interestPageRelatedArticles: [],
            becauseYouReadArticles: nil,
            continueReadingArticles: nil
        ))
    }

    private var laterToday: Date {
        Calendar.current.startOfDay(for: Date()).addingTimeInterval(12 * 60 * 60)
    }

    private var tomorrow: Date {
        Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
    }

    // MARK: - Hide Community Module

    func testHideCommunityFeaturedArticle() async throws {
        await fixture.withConfiguredEnvironment(configure: {}) {
            let (vm, controller) = self.makeViewModel()
            vm.hideModule(.featuredArticle)
            XCTAssertFalse(vm.communityModuleVisibility.featuredArticle)
            XCTAssertFalse(controller.communityFeaturedArticleIsOn())
            XCTAssertTrue(vm.communityModuleVisibility.topRead)
            XCTAssertTrue(vm.communityModuleVisibility.inTheNews)
            XCTAssertTrue(vm.communityModuleVisibility.onThisDay)
            XCTAssertTrue(vm.communityModuleVisibility.pictureOfDay)
        }
    }

    func testHideCommunityTopRead() async throws {
        await fixture.withConfiguredEnvironment(configure: {}) {
            let (vm, controller) = self.makeViewModel()
            vm.hideModule(.topRead)
            XCTAssertFalse(vm.communityModuleVisibility.topRead)
            XCTAssertFalse(controller.communityTopReadIsOn())
            XCTAssertTrue(vm.communityModuleVisibility.featuredArticle)
        }
    }

    func testHideCommunityInTheNews() async throws {
        await fixture.withConfiguredEnvironment(configure: {}) {
            let (vm, controller) = self.makeViewModel()
            vm.hideModule(.inTheNews)
            XCTAssertFalse(vm.communityModuleVisibility.inTheNews)
            XCTAssertFalse(controller.communityInTheNewsIsOn())
        }
    }

    func testHideCommunityOnThisDay() async throws {
        await fixture.withConfiguredEnvironment(configure: {}) {
            let (vm, controller) = self.makeViewModel()
            vm.hideModule(.onThisDay)
            XCTAssertFalse(vm.communityModuleVisibility.onThisDay)
            XCTAssertFalse(controller.communityOnThisDayIsOn())
        }
    }

    func testHideCommunityPictureOfDay() async throws {
        await fixture.withConfiguredEnvironment(configure: {}) {
            let (vm, controller) = self.makeViewModel()
            vm.hideModule(.pictureOfDay)
            XCTAssertFalse(vm.communityModuleVisibility.pictureOfDay)
            XCTAssertFalse(controller.communityPictureOfTheDayIsOn())
        }
    }

    // MARK: - Hide For You Module

    func testHideForYouBasedOnInterests() async throws {
        await fixture.withConfiguredEnvironment(configure: {}) {
            let (vm, controller) = self.makeViewModel()
            vm.hideForYouModule(.basedOnInterests)
            XCTAssertFalse(controller.forYouBasedOnInterestsIsOn())
            XCTAssertTrue(controller.forYouBecauseYouReadIsOn())
            XCTAssertTrue(controller.forYouContinueReadingIsOn())
        }
    }

    func testHideForYouBecauseYouRead() async throws {
        await fixture.withConfiguredEnvironment(configure: {}) {
            let (vm, controller) = self.makeViewModel()
            vm.hideForYouModule(.becauseYouRead)
            XCTAssertFalse(controller.forYouBecauseYouReadIsOn())
            XCTAssertTrue(controller.forYouBasedOnInterestsIsOn())
            XCTAssertTrue(controller.forYouContinueReadingIsOn())
        }
    }

    func testHideForYouContinueReading() async throws {
        await fixture.withConfiguredEnvironment(configure: {}) {
            let (vm, controller) = self.makeViewModel()
            vm.hideForYouModule(.continueReading)
            XCTAssertFalse(controller.forYouContinueReadingIsOn())
        }
    }

    func testHideForYouModuleUpdatesForYouViewModelVisibility() async throws {
        await fixture.withConfiguredEnvironment(configure: {}) {
            let (vm, _) = self.makeViewModel()
            vm.forYouViewModel = self.makeForYouViewModel()
            vm.hideForYouModule(.basedOnInterests)
            XCTAssertFalse(vm.forYouViewModel?.moduleVisibility.basedOnInterests ?? true)
        }
    }

    // MARK: - Hide Card (Community)

    func testHideCardAppendsToHiddenKeys() async throws {
        await fixture.withConfiguredEnvironment(configure: {}) {
            let (vm, _) = self.makeViewModel()
            vm.hideCard(key: "featured_article_Octopus")
            XCTAssertTrue(vm.hiddenCardKeys.contains("featured_article_Octopus"))
        }
    }

    func testHideCardPersistsViaDataController() async throws {
        await fixture.withConfiguredEnvironment(configure: {}) {
            let (vm, controller) = self.makeViewModel()
            vm.hideCard(key: "featured_article_Octopus")
            XCTAssertTrue(controller.isCardHidden(key: "featured_article_Octopus"))
        }
    }

    func testHideMultipleCardsAccumulates() async throws {
        await fixture.withConfiguredEnvironment(configure: {}) {
            let (vm, _) = self.makeViewModel()
            vm.hideCard(key: "card_a")
            vm.hideCard(key: "card_b")
            XCTAssertTrue(vm.hiddenCardKeys.contains("card_a"))
            XCTAssertTrue(vm.hiddenCardKeys.contains("card_b"))
            XCTAssertEqual(vm.hiddenCardKeys.count, 2)
        }
    }

    // MARK: - Hide Card (For You)

    func testHideForYouCardAppendsKey() async throws {
        await fixture.withConfiguredEnvironment(configure: {}) {
            let (vm, controller) = self.makeViewModel()
            let cardVM = self.makeForYouCardViewModel()
            vm.hideForYouCard(cardVM)
            XCTAssertTrue(vm.hiddenCardKeys.contains(cardVM.cardUniqueKey))
            XCTAssertTrue(controller.isCardHidden(key: cardVM.cardUniqueKey))
        }
    }

    func testForYouHideKeyFormat() async throws {
        await fixture.withConfiguredEnvironment(configure: {}) {
            let language = WMFLanguage(languageCode: "en", languageVariantCode: nil)
            let project = WMFProject.wikipedia(language)
            let article = WMFForYouArticle(title: "Octopus", project: project)
            let header = WMFForYouHeaderLabel(format: "Test %1$@", highlight: "")
            let cardVM = WMFForYouArticleCardViewModel(article: article, headerLabel: header)
            XCTAssertEqual(cardVM.cardUniqueKey, "for_you_\(project.id)_Octopus")
        }
    }

    func testHidingACardReachesTheForYouFeed() async throws {
        await fixture.withConfiguredEnvironment(configure: {}) {
            let (vm, _) = self.makeViewModel()
            vm.forYouViewModel = self.makeForYouViewModel()

            vm.hideCard(key: "featured_article_Octopus")

            XCTAssertTrue(vm.forYouViewModel?.hiddenCardKeys.contains("featured_article_Octopus") ?? false,
                          "The For You view model mirrors the hidden keys, and its view reads from that mirror")
        }
    }

    func testAForYouFeedAttachedLaterStartsFromTheHiddenKeysAlreadySet() async throws {
        await fixture.withConfiguredEnvironment(configure: {}) {
            let (vm, _) = self.makeViewModel()
            vm.hideCard(key: "card_hidden_before_the_feed_loaded")

            vm.forYouViewModel = self.makeForYouViewModel()

            XCTAssertTrue(vm.forYouViewModel?.hiddenCardKeys.contains("card_hidden_before_the_feed_loaded") ?? false,
                          "A feed that loads after a card was hidden must not show it again")
        }
    }

    // MARK: - Embedded Community Content

    func testEmbeddedCommunityViewControllerSkipsCommunityFeedLoad() async throws {
        await fixture.withConfiguredEnvironment(configure: {}) {
            let (vm, _) = self.makeViewModel()
            vm.makeEmbeddedCommunityViewController = { UIViewController() }
            vm.selectedLanguage = WMFLanguage(languageCode: "en", languageVariantCode: nil)

            vm.loadCommunityFeedIfNeeded()

            XCTAssertFalse(vm.isLoadingCommunity)
            XCTAssertTrue(vm.communityPages.isEmpty)
        }
    }

    // MARK: - Language Picker Visibility

    func testLanguagePickerHiddenOnCommunityTabWithEmbeddedContent() async throws {
        await fixture.withConfiguredEnvironment(configure: {}) {
            let (vm, _) = self.makeViewModel()
            vm.makeEmbeddedCommunityViewController = { UIViewController() }
            vm.selectedTab = .community
            XCTAssertFalse(vm.shouldShowLanguagePicker)
        }
    }

    func testLanguagePickerShownOnForYouTabWithEmbeddedContent() async throws {
        await fixture.withConfiguredEnvironment(configure: {}) {
            let (vm, _) = self.makeViewModel()
            vm.makeEmbeddedCommunityViewController = { UIViewController() }
            vm.selectedTab = .forYou
            XCTAssertTrue(vm.shouldShowLanguagePicker)
        }
    }

    func testLanguagePickerShownOnCommunityTabWithoutEmbeddedContent() async throws {
        await fixture.withConfiguredEnvironment(configure: {}) {
            let (vm, _) = self.makeViewModel()
            vm.selectedTab = .community
            XCTAssertTrue(vm.shouldShowLanguagePicker)
        }
    }

    // MARK: - Selected Language Clears Feeds

    func testChangingLanguageResetsTheForYouFeed() async throws {
        await fixture.withConfiguredEnvironment(configure: {}) {
            let (vm, _) = self.makeViewModel()
            let english = WMFLanguage(languageCode: "en", languageVariantCode: nil)
            let spanish = WMFLanguage(languageCode: "es", languageVariantCode: nil)

            vm.selectedLanguage = english
            vm.forYouViewModel = self.makeForYouViewModel()
            vm.forYouFeedError = URLError(.notConnectedToInternet)
            XCTAssertNotNil(vm.forYouViewModel)

            vm.selectedLanguage = spanish

            XCTAssertNil(vm.forYouViewModel)
            XCTAssertNil(vm.forYouFeedError, "The error described the previous language's fetch, so it must not stay on screen while the new one is loaded")
            XCTAssertTrue(vm.communityPages.isEmpty)
        }
    }

    func testChangingLanguageClearsCommunityFeed() async throws {
        await fixture.withConfiguredEnvironment(configure: {}) {
            let (vm, _) = self.makeViewModel()
            let english = WMFLanguage(languageCode: "en", languageVariantCode: nil)
            let spanish = WMFLanguage(languageCode: "es", languageVariantCode: nil)

            vm.selectedLanguage = english
            vm.selectedLanguage = spanish

            XCTAssertTrue(vm.communityPages.isEmpty)
        }
    }

    func testSettingSameLanguageDoesNotClearForYouFeed() async throws {
        await fixture.withConfiguredEnvironment(configure: {}) {
            let (vm, _) = self.makeViewModel()
            let english = WMFLanguage(languageCode: "en", languageVariantCode: nil)
            vm.selectedLanguage = english
            vm.forYouViewModel = self.makeForYouViewModel()

            vm.selectedLanguage = english

            XCTAssertNotNil(vm.forYouViewModel)
        }
    }

    // MARK: - Daily Refresh

    func testFeedIsDiscardedWhenTheDayChanges() async throws {
        await fixture.withConfiguredEnvironment(configure: {}) {
            let (vm, _) = self.makeViewModel()
            vm.forYouViewModel = self.makeForYouViewModel()

            vm.refreshFeedsIfDayChanged(now: self.tomorrow)

            XCTAssertNil(vm.forYouViewModel)
        }
    }

    func testFeedIsKeptWithinTheSameDay() async throws {
        await fixture.withConfiguredEnvironment(configure: {}) {
            let (vm, _) = self.makeViewModel()
            vm.forYouViewModel = self.makeForYouViewModel()

            vm.refreshFeedsIfDayChanged(now: self.laterToday)

            XCTAssertNotNil(vm.forYouViewModel)
        }
    }

    func testDayChangeDoesNothingWhenNoFeedIsLoaded() async throws {
        await fixture.withConfiguredEnvironment(configure: {}) {
            let (vm, _) = self.makeViewModel()

            vm.refreshFeedsIfDayChanged(now: self.tomorrow)

            XCTAssertNil(vm.forYouViewModel)
            XCTAssertFalse(vm.isLoadingForYou)
            XCTAssertFalse(vm.isLoadingCommunity)
        }
    }

    func testDayChangeClearsAnEarlierError() async throws {
        await fixture.withConfiguredEnvironment(configure: {}) {
            let (vm, _) = self.makeViewModel()
            vm.forYouViewModel = self.makeForYouViewModel()
            vm.forYouFeedError = NSError(domain: "test", code: 1)

            vm.refreshFeedsIfDayChanged(now: self.tomorrow)

            XCTAssertNil(vm.forYouFeedError)
        }
    }

    // MARK: - Refresh Indicator

    func testRefreshIndicatorStartsOff() async throws {
        await fixture.withConfiguredEnvironment(configure: {}) {
            let (vm, _) = self.makeViewModel()
            XCTAssertFalse(vm.isRefreshingForYou)
        }
    }

    func testRefreshIndicatorStaysOnAfterTheRefreshReturns() async throws {
        await fixture.withConfiguredEnvironment(configure: {}) {
            let (vm, _) = self.makeViewModel()
            let store = WMFDataEnvironment.current.coreDataStore
            WMFDataEnvironment.current.coreDataStore = nil
            defer { WMFDataEnvironment.current.coreDataStore = store }

            vm.selectedLanguage = WMFLanguage(languageCode: "en", languageVariantCode: nil)

            let start = Date()
            await vm.refreshForYouFeed(minimumIndicatorDuration: 0.2)

            XCTAssertTrue(vm.isRefreshingForYou)

            await vm.refreshIndicatorTask?.value

            XCTAssertGreaterThanOrEqual(Date().timeIntervalSince(start), 0.2)
            XCTAssertFalse(vm.isRefreshingForYou)
        }
    }

    func testRefreshWithNoLanguageDoesNotShowTheIndicator() async throws {
        await fixture.withConfiguredEnvironment(configure: {}) {
            let (vm, _) = self.makeViewModel()
            vm.selectedLanguage = nil

            await vm.refreshForYouFeed(minimumIndicatorDuration: 0.2)

            XCTAssertFalse(vm.isRefreshingForYou)
        }
    }
}
