import Testing
import Foundation
@testable import WMFComponents
@testable import WMFData

/// The preloader has one promise: the module that the reader opens next is already fetched, with
/// the same cache keys that the card view models use. The preloader does not fetch more of the feed.
@MainActor
@Suite
struct WMFForYouModulePreloaderTests {

    private let project = WMFProject.wikipedia(WMFLanguage(languageCode: "en", languageVariantCode: nil))

    private func page(_ interest: String, _ titles: [String]) -> WMFForYouPageViewModel {
        let header = WMFForYouHeaderLabel(format: "Because of your interest: %1$@", highlight: interest)
        let articles = titles.map { WMFForYouArticle(title: $0, project: project) }
        return WMFForYouPageViewModel(module: .basedOnInterests, headerLabel: header, articles: articles)
    }

    private func makePreloader() -> (WMFForYouModulePreloader, MockArticleSummaryDataController) {
        let summaryController = MockArticleSummaryDataController()
        let preloader = WMFForYouModulePreloader(summaryDataController: summaryController, preloadsImages: false)
        return (preloader, summaryController)
    }

    // MARK: - Initial modules

    @Test
    func initialPreloadCoversExactlyTheFirstTwoModules() async {
        let (preloader, summaryController) = makePreloader()
        let pages = [page("Biology", ["A1", "A2"]), page("History", ["B1"]), page("Music", ["C1"])]

        preloader.preloadInitialModules(in: pages)
        await preloader.waitForAllPreloadTasks()

        #expect(await summaryController.requestedTitles.sorted() == ["A1", "A2", "B1"])
    }

    @Test
    func aFeedWithOneModulePreloadsJustThatModule() async {
        let (preloader, summaryController) = makePreloader()

        preloader.preloadInitialModules(in: [page("Biology", ["A1"])])
        await preloader.waitForAllPreloadTasks()

        #expect(await summaryController.requestedTitles == ["A1"])
    }

    // MARK: - The next module

    @Test
    func settlingOnAModulePreloadsTheOneAfterIt() async {
        let (preloader, summaryController) = makePreloader()
        let pages = [page("Biology", ["A1"]), page("History", ["B1"]), page("Music", ["C1"])]

        preloader.preloadModule(after: pages[1].id, in: pages)
        await preloader.waitForAllPreloadTasks()

        #expect(await summaryController.requestedTitles == ["C1"])
    }

    @Test
    func theLastModuleHasNothingAfterItToPreload() async {
        let (preloader, summaryController) = makePreloader()
        let pages = [page("Biology", ["A1"]), page("History", ["B1"])]

        preloader.preloadModule(after: pages[1].id, in: pages)
        await preloader.waitForAllPreloadTasks()

        #expect(await summaryController.requestedTitles.isEmpty)
    }

    @Test
    func anUnknownModuleTriggersNoPreload() async {
        let (preloader, summaryController) = makePreloader()

        preloader.preloadModule(after: UUID(), in: [page("Biology", ["A1"])])
        preloader.preloadModule(after: nil, in: [page("Biology", ["A1"])])
        await preloader.waitForAllPreloadTasks()

        #expect(await summaryController.requestedTitles.isEmpty)
    }

    // MARK: - No repeated work

    @Test
    func aModuleIsFetchedOnlyOnceAcrossRepeatedTriggers() async {
        let (preloader, summaryController) = makePreloader()
        let pages = [page("Biology", ["A1"]), page("History", ["B1"])]

        preloader.preloadInitialModules(in: pages)
        preloader.preloadModule(after: pages[0].id, in: pages)
        preloader.preloadModule(after: pages[0].id, in: pages)
        await preloader.waitForAllPreloadTasks()

        #expect(await summaryController.requestedTitles.sorted() == ["A1", "B1"])
    }

    // MARK: - Hidden cards

    @Test
    func hiddenCardsAreNotFetched() async {
        let (preloader, summaryController) = makePreloader()
        let pages = [page("Biology", ["A1", "A2"])]
        let hiddenKey = pages[0].articleViewModels[0].cardUniqueKey

        preloader.preloadInitialModules(in: pages, hiddenCardKeys: [hiddenKey])
        await preloader.waitForAllPreloadTasks()

        #expect(await summaryController.requestedTitles == ["A2"])
    }

    // MARK: - Cache keys

    /// The summary cache uses the exact title string as its key. The preloader must send the
    /// card's title with no changes. That title is the display form, with underscores replaced.
    /// A different spelling fills a cache entry that the card does not read.
    @Test
    func titlesAreFetchedExactlyAsTheCardWillFetchThem() async {
        let (preloader, summaryController) = makePreloader()
        let pages = [page("Biology", ["Giant_squid"])]
        let cardTitle = pages[0].articleViewModels[0].title

        preloader.preloadInitialModules(in: pages)
        await preloader.waitForAllPreloadTasks()

        #expect(cardTitle == "Giant squid")
        #expect(await summaryController.requestedTitles == [cardTitle])
    }
}

// MARK: - Mocks

/// Records each summary request. The feed view model tests and the onboarding tests also use
/// this mock, because those tests must not let the preloader send requests to the network
/// singleton. The `thumbnailURL` must stay nil: a thumbnail makes the preloader fetch the image
/// through the real image controller, and the tests then reach the network.
actor MockArticleSummaryDataController: WMFArticleSummaryDataControlling {

    private(set) var requestedTitles: [String] = []

    func fetchArticleSummary(project: WMFProject, title: String) async throws -> WMFArticleSummary {
        requestedTitles.append(title)
        return WMFArticleSummary(displayTitle: title, description: "A description", extractHtml: "", thumbnailURL: nil, extract: "An extract")
    }
}
