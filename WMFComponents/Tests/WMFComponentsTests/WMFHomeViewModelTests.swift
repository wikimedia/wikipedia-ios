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
        let vm = WMFHomeViewModel(dataController: controller)
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

    /// Waits on the main actor until `condition` holds. Gives up after about two seconds, so a
    /// broken test fails instead of hanging the suite.
    private func waitUntil(_ condition: () -> Bool) async -> Bool {
        for _ in 0..<200 {
            if condition() { return true }
            try? await Task.sleep(nanoseconds: 10_000_000)
        }
        return condition()
    }

    private let emptyFeed = WMFFeedAPIResponse(todaysFeaturedArticle: nil, mostRead: nil, image: nil, news: nil)

    /// The English load is still in flight when the reader picks Spanish, and it finishes after the
    /// Spanish feed is on screen. It belongs to the old language, so it must not replace that feed.
    func testACommunityLoadFinishingAfterALanguageChangeIsDropped() async {
        let english = WMFLanguage(languageCode: "en", languageVariantCode: nil)
        let spanish = WMFLanguage(languageCode: "es", languageVariantCode: nil)
        let englishProjectID = WMFProject.wikipedia(english).id
        let feed = WMFMockGatedFeedDataController(response: emptyFeed) { project, _ in
            project.id == englishProjectID
        }
        let vm = WMFHomeViewModel(dataController: WMFHomeDataController(feedDataController: feed, userDefaultsStore: WMFMockKeyValueStore()))
        vm.selectedTab = .community

        vm.selectedLanguage = english
        let englishIsHeld = await feed.waitUntilHeld()
        XCTAssertTrue(englishIsHeld)

        vm.selectedLanguage = spanish
        let spanishLoaded = await waitUntil { !vm.communityPages.isEmpty }
        XCTAssertTrue(spanishLoaded)

        await feed.releaseHeld()
        // Give the English task the time to finish and, without its cancellation checks, write.
        try? await Task.sleep(nanoseconds: 200_000_000)

        XCTAssertEqual(vm.communityPages.map(\.project.id), [WMFProject.wikipedia(spanish).id])
        XCTAssertFalse(vm.isLoadingCommunity)
        XCTAssertNil(vm.communityFeedError)
    }

    // MARK: - Community empty feed and errors

    func testCommunityFeedIsEmptyWhenEveryModuleIsOff() async {
        let feed = WMFMockGatedFeedDataController(response: emptyFeed, holdCount: 0) { _, _ in false }
        let controller = WMFHomeDataController(feedDataController: feed, userDefaultsStore: WMFMockKeyValueStore())
        controller.setCommunityFeaturedArticleIsOn(false)
        controller.setCommunityTopReadIsOn(false)
        controller.setCommunityInTheNewsIsOn(false)
        controller.setCommunityOnThisDayIsOn(false)
        controller.setCommunityPictureOfTheDayIsOn(false)
        let vm = WMFHomeViewModel(dataController: controller)
        vm.selectedTab = .community
        vm.selectedLanguage = WMFLanguage(languageCode: "en", languageVariantCode: nil)
        let loaded = await waitUntil { !vm.communityPages.isEmpty }
        XCTAssertTrue(loaded)

        XCTAssertTrue(vm.isCommunityFeedEmpty)
    }

    /// Hiding every card of today from the menu must not trap the reader in the empty state: its
    /// button opens settings, which cannot unhide cards, and the feed's "See past" would be gone.
    func testHidingEveryCardKeepsTheFeed() async {
        let tfa = try? JSONDecoder().decode(WMFFeedAPIResponse.self, from: Data(#"{ "tfa": { "title": "Black_hole" } }"#.utf8))
        let feed = WMFMockGatedFeedDataController(response: tfa ?? emptyFeed, holdCount: 0) { _, _ in false }
        let vm = WMFHomeViewModel(dataController: WMFHomeDataController(feedDataController: feed, userDefaultsStore: WMFMockKeyValueStore()))
        vm.selectedTab = .community
        vm.selectedLanguage = WMFLanguage(languageCode: "en", languageVariantCode: nil)
        let loaded = await waitUntil { !vm.communityPages.isEmpty }
        XCTAssertTrue(loaded)

        for page in vm.communityPages {
            for module in WMFCommunityModule.allCases {
                if let key = page.hideKey(for: module) { vm.hideCard(key: key) }
            }
        }

        XCTAssertFalse(vm.isCommunityFeedEmpty)
    }

    func testTappingACommunityArticleReachesTheCoordinatorWithItsModuleAndAction() {
        let (vm, _) = makeViewModel()
        let project = WMFProject.wikipedia(WMFLanguage(languageCode: "ar", languageVariantCode: nil))
        var opened: (String, String, WMFCommunityModule, WMFCommunityArticleAction)?
        vm.didTapCommunityArticle = { title, project, module, action in opened = (title, project.id, module, action) }

        vm.performCommunityArticleAction(.openInBackgroundTab, title: "Black_hole", project: project, module: .topRead)

        XCTAssertEqual(opened?.0, "Black_hole")
        XCTAssertEqual(opened?.1, project.id)
        XCTAssertEqual(opened?.2, .topRead)
        XCTAssertEqual(opened?.3, .openInBackgroundTab)
    }

    /// The Save button turns into "Saved for later" at once, before the saved list reports back.
    func testSavingACommunityArticleMarksItSaved() {
        let (vm, _) = makeViewModel()
        let project = WMFProject.wikipedia(WMFLanguage(languageCode: "en", languageVariantCode: nil))
        vm.didTapCommunityArticle = { _, _, _, _ in }

        vm.performCommunityArticleAction(.save, title: "Black_hole", project: project, module: .featuredArticle)
        XCTAssertTrue(vm.isCommunityArticleSaved(title: "Black_hole", project: project))

        vm.performCommunityArticleAction(.unsave, title: "Black_hole", project: project, module: .featuredArticle)
        XCTAssertFalse(vm.isCommunityArticleSaved(title: "Black_hole", project: project))
    }

    func testSavedStatesComeFromTheCoordinatorForLoadedArticles() async {
        let tfa = try? JSONDecoder().decode(WMFFeedAPIResponse.self, from: Data(#"{ "tfa": { "title": "Black_hole" }, "mostread": { "articles": [ { "title": "Octopus" } ] } }"#.utf8))
        let feed = WMFMockGatedFeedDataController(response: tfa ?? emptyFeed, holdCount: 0) { _, _ in false }
        let vm = WMFHomeViewModel(dataController: WMFHomeDataController(feedDataController: feed, userDefaultsStore: WMFMockKeyValueStore()))
        vm.isCommunityArticleSaved = { title, _ in title == "Octopus" }
        vm.selectedTab = .community
        vm.selectedLanguage = WMFLanguage(languageCode: "en", languageVariantCode: nil)
        let loaded = await waitUntil { !vm.communityPages.isEmpty }
        XCTAssertTrue(loaded)

        let project = WMFProject.wikipedia(WMFLanguage(languageCode: "en", languageVariantCode: nil))
        XCTAssertTrue(vm.isCommunityArticleSaved(title: "Octopus", project: project))
        XCTAssertFalse(vm.isCommunityArticleSaved(title: "Black_hole", project: project))
    }

    func testMoreTopReadReachesTheCoordinatorWithEveryTitle() throws {
        let (vm, _) = makeViewModel()
        let project = WMFProject.wikipedia(WMFLanguage(languageCode: "en", languageVariantCode: nil))
        let feedResponse = try JSONDecoder().decode(WMFFeedAPIResponse.self, from: Data(#"{ "mostread": { "articles": [ { "title": "A" }, { "title": "B" }, { "title": "C" }, { "title": "D" }, { "title": "E" }, { "title": "F" } ] } }"#.utf8))
        let page = WMFHomeCommunityViewModel(response: WMFCommunityResponse(date: Date(), feedResponse: feedResponse, onThisDay: nil), project: project)
        var opened: [String]?
        vm.didTapCommunityTopReadList = { titles, _, _ in opened = titles }

        vm.openCommunityTopReadList(for: page)

        XCTAssertEqual(opened, ["A", "B", "C", "D", "E", "F"])
    }

    func testTappingAnOnThisDayEventReachesTheCoordinatorWithThatEvent() throws {
        let (vm, _) = makeViewModel()
        let project = WMFProject.wikipedia(WMFLanguage(languageCode: "en", languageVariantCode: nil))
        let feedResponse = try JSONDecoder().decode(WMFFeedAPIResponse.self, from: Data(#"{ "onthisday": [ { "text": "Nuremberg trials begin", "year": 1945, "pages": [] } ] }"#.utf8))
        let page = WMFHomeCommunityViewModel(response: WMFCommunityResponse(date: Date(), feedResponse: feedResponse, onThisDay: nil), project: project)
        var opened: (year: Int, text: String)?
        var didOpen = false
        vm.didTapCommunityOnThisDay = { _, _, event in
            didOpen = true
            opened = event
        }

        vm.openCommunityOnThisDay(for: page, event: page.onThisDayItems?.first)
        XCTAssertEqual(opened?.year, 1945)
        XCTAssertEqual(opened?.text, "Nuremberg trials begin")

        vm.openCommunityOnThisDay(for: page, event: nil)
        XCTAssertTrue(didOpen)
        XCTAssertNil(opened, "More on this day opens the list at its top")
    }

    func testTappingANewsStoryReachesTheCoordinatorWithTheWholeStory() throws {
        let (vm, _) = makeViewModel()
        let story = try JSONDecoder().decode(WMFFeedNewsItem.self, from: Data(#"{ "story": "A story", "links": [ { "title": "A" }, { "title": "B" } ] }"#.utf8))
        var opened: WMFFeedNewsItem?
        vm.didTapCommunityNewsStory = { story, _ in opened = story }

        vm.openCommunityNewsStory(story, project: .wikipedia(WMFLanguage(languageCode: "en", languageVariantCode: nil)))

        XCTAssertEqual(opened?.links?.compactMap(\.title), ["A", "B"])
    }

    func testTappingThePictureOfTheDayReachesTheCoordinatorWithItsDate() {
        let (vm, _) = makeViewModel()
        let date = Date(timeIntervalSince1970: 1_700_000_000)
        var opened: Date?
        vm.didTapCommunityPictureOfTheDay = { opened = $0 }

        vm.openCommunityPictureOfTheDay(date: date)

        XCTAssertEqual(opened, date)
    }

    func testCommunityFeedIsNotEmptyBeforeItLoads() {
        let (vm, _) = makeViewModel()
        XCTAssertFalse(vm.isCommunityFeedEmpty, "Loading and error states have their own views")
    }

    func testOfflineErrorsGetTheOfflineCopy() {
        let (vm, _) = makeViewModel()
        let offline = URLError(.notConnectedToInternet)
        XCTAssertEqual(vm.communityErrorTitle(for: offline), vm.forYouErrorTitle)
        XCTAssertEqual(vm.communityErrorSubtitle(for: offline), vm.forYouErrorSubtitle)
    }

    func testAWrappedOfflineErrorGetsTheOfflineCopy() {
        let (vm, _) = makeViewModel()
        let wrapped = NSError(domain: "WMFService", code: 1, userInfo: [NSUnderlyingErrorKey: URLError(.networkConnectionLost) as NSError])
        XCTAssertEqual(vm.communityErrorTitle(for: wrapped), vm.forYouErrorTitle)
    }

    func testOtherErrorsDoNotTellAnOnlineReaderToConnect() {
        let (vm, _) = makeViewModel()
        let serverError = URLError(.badServerResponse)
        XCTAssertEqual(vm.communityErrorTitle(for: serverError), vm.communityLoadErrorTitle)
        XCTAssertNotEqual(vm.communityErrorTitle(for: serverError), vm.forYouErrorTitle)
        XCTAssertEqual(vm.communityErrorTitle(for: DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: ""))), vm.communityLoadErrorTitle)
    }

    func testChangingLanguageStopsTheForYouLoadInFlight() {
        let (vm, _) = makeViewModel()
        vm.selectedTab = .forYou
        vm.selectedLanguage = WMFLanguage(languageCode: "en", languageVariantCode: nil)
        vm.loadForYouFeedIfNeeded()
        XCTAssertTrue(vm.isLoadingForYou)

        vm.selectedLanguage = WMFLanguage(languageCode: "es", languageVariantCode: nil)

        XCTAssertTrue(vm.isLoadingForYou)
        XCTAssertNil(vm.forYouViewModel)
    }

    func testPreviousPageNeedsAFirstPage() {
        let (vm, _) = makeViewModel()
        vm.selectedLanguage = WMFLanguage(languageCode: "en", languageVariantCode: nil)

        vm.loadCommunityPreviousPage()

        XCTAssertFalse(vm.isLoadingCommunityPreviousPage)
        XCTAssertNil(vm.communityPreviousPageError)
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

    // MARK: - Logging helpers

    private func makeCard(title: String, module: WMFForYouModule) -> WMFForYouArticleCardViewModel {
        let article = WMFForYouArticle(title: title, project: .wikipedia(WMFLanguage(languageCode: "en", languageVariantCode: nil)))
        let header = WMFForYouHeaderLabel(format: "Test %1$@", highlight: "")
        return WMFForYouArticleCardViewModel(article: article, headerLabel: header, module: module)
    }

    // MARK: - Impression deduplication

    func testCardImpressionFiresOnFirstShow() {
        let (vm, _) = makeViewModel()
        var impressions: [(String, Int)] = []
        vm.logCardImpression = { impressions.append(($0, $1)) }
        vm.forYouViewModel = makeForYouViewModel()

        let card = makeCard(title: "Octopus", module: .becauseYouRead)
        vm.forYouViewModel?.onShowCard?(card)

        XCTAssertEqual(impressions.count, 1)
        XCTAssertEqual(impressions.first?.0, "BecauseYouReadCard")
        XCTAssertEqual(impressions.first?.1, card.cardIndex)
    }

    func testCardImpressionDeduplicatesRepeatedShows() {
        let (vm, _) = makeViewModel()
        var impressionCount = 0
        vm.logCardImpression = { _, _ in impressionCount += 1 }
        vm.forYouViewModel = makeForYouViewModel()

        let card = makeCard(title: "Octopus", module: .becauseYouRead)
        vm.forYouViewModel?.onShowCard?(card)
        vm.forYouViewModel?.onShowCard?(card)
        vm.forYouViewModel?.onShowCard?(card)

        XCTAssertEqual(impressionCount, 1, "The same card appearing multiple times must log only one impression")
    }

    func testCardImpressionFiresAgainForDifferentCard() {
        let (vm, _) = makeViewModel()
        var impressionCount = 0
        vm.logCardImpression = { _, _ in impressionCount += 1 }
        vm.forYouViewModel = makeForYouViewModel()

        let card1 = makeCard(title: "Octopus", module: .becauseYouRead)
        let card2 = makeCard(title: "Squid", module: .becauseYouRead)
        vm.forYouViewModel?.onShowCard?(card1)
        vm.forYouViewModel?.onShowCard?(card1)
        vm.forYouViewModel?.onShowCard?(card2)

        XCTAssertEqual(impressionCount, 2, "A new card must log a fresh impression even after a duplicate was suppressed")
    }

    // MARK: - Save / unsave routing

    func testSaveCardCallsLogCardDidSave() {
        let (vm, _) = makeViewModel()
        var savedCard: WMFForYouArticleCardViewModel?
        var unsavedCard: WMFForYouArticleCardViewModel?
        vm.logCardDidSave = { savedCard = $0 }
        vm.logCardDidUnsave = { unsavedCard = $0 }
        vm.forYouViewModel = makeForYouViewModel()

        let card = makeForYouCardViewModel()
        vm.forYouViewModel?.onSaveCard?(card)

        XCTAssertTrue(savedCard === card)
        XCTAssertNil(unsavedCard, "Saving must not trigger the unsave callback")
    }

    func testUnsaveCardCallsLogCardDidUnsave() {
        let (vm, _) = makeViewModel()
        var savedCard: WMFForYouArticleCardViewModel?
        var unsavedCard: WMFForYouArticleCardViewModel?
        vm.logCardDidSave = { savedCard = $0 }
        vm.logCardDidUnsave = { unsavedCard = $0 }
        vm.forYouViewModel = makeForYouViewModel()

        let card = makeForYouCardViewModel()
        vm.forYouViewModel?.onUnsaveCard?(card)

        XCTAssertTrue(unsavedCard === card)
        XCTAssertNil(savedCard, "Unsaving must not trigger the save callback")
    }

    // MARK: - Customize interests routing

    func testCustomizeInterestsFromCardPassesModuleLoggingId() {
        let (vm, _) = makeViewModel()
        var capturedActionSource: String?
        var capturedElementId: String?
        vm.logDidTapCustomizeInterests = { capturedActionSource = $0; capturedElementId = $1 }
        vm.forYouViewModel = makeForYouViewModel()

        let card = makeCard(title: "Octopus", module: .becauseYouRead)
        vm.forYouViewModel?.onCustomizeInterests?(.card(card))

        XCTAssertEqual(capturedActionSource, "BecauseYouReadCard")
        XCTAssertEqual(capturedElementId, "feed_customize")
    }

    func testCustomizeInterestsFromEmptyFeedPassesEmptySource() {
        let (vm, _) = makeViewModel()
        var capturedActionSource: String?
        var capturedElementId: String?
        vm.logDidTapCustomizeInterests = { capturedActionSource = $0; capturedElementId = $1 }
        vm.forYouViewModel = makeForYouViewModel()

        vm.forYouViewModel?.onCustomizeInterests?(.emptyFeed)

        XCTAssertEqual(capturedActionSource, "feed_empty")
        XCTAssertEqual(capturedElementId, "customize_feed")
    }

}
