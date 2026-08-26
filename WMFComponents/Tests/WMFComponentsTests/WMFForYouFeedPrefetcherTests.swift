import Testing
import Foundation
@testable import WMFComponents
@testable import WMFData

/// The prefetcher has one promise: the module that the reader opens next is already fetched, with
/// the same cache keys that the card view models use. The prefetcher does not fetch more of the feed.
@MainActor
@Suite
struct WMFForYouFeedPrefetcherTests {

    private let project = WMFProject.wikipedia(WMFLanguage(languageCode: "en", languageVariantCode: nil))

    private func page(_ interest: String, _ titles: [String]) -> WMFForYouPageViewModel {
        let header = WMFForYouHeaderLabel(format: "Because of your interest: %1$@", highlight: interest)
        let articles = titles.map { WMFForYouArticle(title: $0, project: project) }
        return WMFForYouPageViewModel(module: .basedOnInterests, headerLabel: header, articles: articles)
    }

    private func makePrefetcher() -> (WMFForYouFeedPrefetcher, MockArticleSummaryDataController) {
        let summaryController = MockArticleSummaryDataController()
        let prefetcher = WMFForYouFeedPrefetcher(summaryDataController: summaryController, prefetchesImages: false)
        return (prefetcher, summaryController)
    }

    // MARK: - Initial modules

    @Test
    func initialPrefetchCoversExactlyTheFirstTwoModules() async {
        let (prefetcher, summaryController) = makePrefetcher()
        let pages = [page("Biology", ["A1", "A2"]), page("History", ["B1"]), page("Music", ["C1"])]

        prefetcher.prefetchInitialModules(in: pages)
        await prefetcher.waitForAllPrefetchTasks()

        #expect(await summaryController.requestedTitles.sorted() == ["A1", "A2", "B1"])
    }

    @Test
    func aFeedWithOneModulePrefetchesJustThatModule() async {
        let (prefetcher, summaryController) = makePrefetcher()

        prefetcher.prefetchInitialModules(in: [page("Biology", ["A1"])])
        await prefetcher.waitForAllPrefetchTasks()

        #expect(await summaryController.requestedTitles == ["A1"])
    }

    // MARK: - The next module

    @Test
    func settlingOnAModulePrefetchesTheOneAfterIt() async {
        let (prefetcher, summaryController) = makePrefetcher()
        let pages = [page("Biology", ["A1"]), page("History", ["B1"]), page("Music", ["C1"])]

        prefetcher.prefetchModule(after: pages[1].id, in: pages)
        await prefetcher.waitForAllPrefetchTasks()

        #expect(await summaryController.requestedTitles == ["C1"])
    }

    @Test
    func theLastModuleHasNothingAfterItToPrefetch() async {
        let (prefetcher, summaryController) = makePrefetcher()
        let pages = [page("Biology", ["A1"]), page("History", ["B1"])]

        prefetcher.prefetchModule(after: pages[1].id, in: pages)
        await prefetcher.waitForAllPrefetchTasks()

        #expect(await summaryController.requestedTitles.isEmpty)
    }

    @Test
    func anUnknownModuleTriggersNoPrefetch() async {
        let (prefetcher, summaryController) = makePrefetcher()

        prefetcher.prefetchModule(after: UUID(), in: [page("Biology", ["A1"])])
        prefetcher.prefetchModule(after: nil, in: [page("Biology", ["A1"])])
        await prefetcher.waitForAllPrefetchTasks()

        #expect(await summaryController.requestedTitles.isEmpty)
    }

    // MARK: - No repeated work

    @Test
    func aModuleIsFetchedOnlyOnceAcrossRepeatedTriggers() async {
        let (prefetcher, summaryController) = makePrefetcher()
        let pages = [page("Biology", ["A1"]), page("History", ["B1"])]

        prefetcher.prefetchInitialModules(in: pages)
        prefetcher.prefetchModule(after: pages[0].id, in: pages)
        prefetcher.prefetchModule(after: pages[0].id, in: pages)
        await prefetcher.waitForAllPrefetchTasks()

        #expect(await summaryController.requestedTitles.sorted() == ["A1", "B1"])
    }

    // MARK: - Hidden cards

    @Test
    func hiddenCardsAreNotFetched() async {
        let (prefetcher, summaryController) = makePrefetcher()
        let pages = [page("Biology", ["A1", "A2"])]
        let hiddenKey = pages[0].articleViewModels[0].cardUniqueKey

        prefetcher.prefetchInitialModules(in: pages, hiddenCardKeys: [hiddenKey])
        await prefetcher.waitForAllPrefetchTasks()

        #expect(await summaryController.requestedTitles == ["A2"])
    }

    // MARK: - Cache keys

    /// The summary cache uses the exact title string as its key. The prefetcher must send the
    /// card's title with no changes. That title is the display form, with underscores replaced.
    /// A different spelling fills a cache entry that the card does not read.
    @Test
    func titlesAreFetchedExactlyAsTheCardWillFetchThem() async {
        let (prefetcher, summaryController) = makePrefetcher()
        let pages = [page("Biology", ["Giant_squid"])]
        let cardTitle = pages[0].articleViewModels[0].title

        prefetcher.prefetchInitialModules(in: pages)
        await prefetcher.waitForAllPrefetchTasks()

        #expect(cardTitle == "Giant squid")
        #expect(await summaryController.requestedTitles == [cardTitle])
    }
}

// MARK: - Mocks

/// Records each summary request. The feed view model tests also use this mock, because those
/// tests must not let the prefetcher send requests to the network singleton.
actor MockArticleSummaryDataController: WMFArticleSummaryDataControlling {

    private(set) var requestedTitles: [String] = []

    func fetchArticleSummary(project: WMFProject, title: String) async throws -> WMFArticleSummary {
        requestedTitles.append(title)
        return WMFArticleSummary(displayTitle: title, description: "A description", extractHtml: "", thumbnailURL: nil, extract: "An extract")
    }
}

extension WMFForYouFeedPrefetcher {
    /// A prefetcher for tests that do not examine the prefetch itself.
    static func makeMocked() -> WMFForYouFeedPrefetcher {
        WMFForYouFeedPrefetcher(summaryDataController: MockArticleSummaryDataController(), prefetchesImages: false)
    }
}
