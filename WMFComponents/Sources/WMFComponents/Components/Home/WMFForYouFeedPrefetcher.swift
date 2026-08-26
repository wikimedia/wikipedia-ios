import Foundation
import WMFData

/// Loads the data for the module that comes after the one on the screen. The cards of that module
/// then show complete when they appear.
///
/// The prefetcher loads only the next module, not the full feed. A full prefetch uses too much of
/// the reader's data. The prefetcher fetches through the same singletons as the card. Because of
/// this, the card's own `load()` gets its data from the cache. The two data controllers also merge
/// equal requests that are in flight. A card that appears during a prefetch shares the download.
@MainActor
final class WMFForYouFeedPrefetcher {

    /// The data that a prefetch needs from a card. This is a Sendable copy, made before the
    /// fan-out. The title must stay exactly equal to the title in the card view model. The summary
    /// cache uses the title string as its key. A different spelling makes the card's fetch a miss.
    private nonisolated struct CardInput: Sendable {
        let project: WMFProject
        let title: String
    }

    private let summaryDataController: WMFArticleSummaryDataControlling & Sendable

    /// If true, the prefetch also loads the image and its sampled colour. This costs up to four
    /// 1280px downloads for each module. The flag makes a revert a one-line change.
    private let prefetchesImages: Bool

    private var prefetchedPageIDs: Set<UUID> = []
    private var tasks: [Task<Void, Never>] = []

    init(
        summaryDataController: WMFArticleSummaryDataControlling & Sendable = WMFArticleSummaryDataController.shared,
        prefetchesImages: Bool = true
    ) {
        self.summaryDataController = summaryDataController
        self.prefetchesImages = prefetchesImages
    }

    /// Loads the first two modules when the feed is built. The first module has a lazy carousel,
    /// and only its leading cards load on appearance. The second module then shows complete cards
    /// on the first swipe.
    func prefetchInitialModules(in pages: [WMFForYouPageViewModel], hiddenCardKeys: Set<String> = []) {
        prefetch(pages: Array(pages.prefix(2)), hiddenCardKeys: hiddenCardKeys)
    }

    /// Loads the module that comes after the module with the given ID. The `pages` array must
    /// contain only the modules that the view shows. If it contains hidden modules, the prefetch
    /// can load a module that the reader does not see.
    func prefetchModule(after moduleID: UUID?, in pages: [WMFForYouPageViewModel], hiddenCardKeys: Set<String> = []) {
        guard let moduleID,
              let index = pages.firstIndex(where: { $0.id == moduleID }),
              index + 1 < pages.count else {
            return
        }
        prefetch(pages: [pages[index + 1]], hiddenCardKeys: hiddenCardKeys)
    }

    private func prefetch(pages: [WMFForYouPageViewModel], hiddenCardKeys: Set<String>) {
        for page in pages {
            guard prefetchedPageIDs.insert(page.id).inserted else { continue }

            let cards = page.articleViewModels
                .filter { !hiddenCardKeys.contains($0.cardUniqueKey) }
                .map { CardInput(project: $0.project, title: $0.title) }
            guard !cards.isEmpty else { continue }

            let summaryDataController = self.summaryDataController
            let prefetchesImages = self.prefetchesImages
            let task = Task {
                await withTaskGroup(of: Void.self) { group in
                    for card in cards {
                        group.addTask {
                            await Self.prefetchCard(card, summaryDataController: summaryDataController, prefetchesImages: prefetchesImages)
                        }
                    }
                }
            }
            tasks.append(task)
        }
    }

    /// Does the same fetches as `WMFForYouArticleCardViewModel.load()`, in the same sequence. Each
    /// URL and cache key must be equal to what the card requests.
    private nonisolated static func prefetchCard(
        _ card: CardInput,
        summaryDataController: WMFArticleSummaryDataControlling & Sendable,
        prefetchesImages: Bool
    ) async {
        guard let summary = try? await summaryDataController.fetchArticleSummary(project: card.project, title: card.title) else {
            return
        }
        guard prefetchesImages, let thumbnailURL = summary.thumbnailURL else {
            return
        }

        let data: Data
        if let largeURL = await WMFForYouArticleCardViewModel.upsizedThumbnailURL(from: thumbnailURL),
           let largeData = try? await WMFImageDataController.shared.fetchImageData(url: largeURL) {
            data = largeData
        } else if let originalData = try? await WMFImageDataController.shared.fetchImageData(url: thumbnailURL) {
            data = originalData
        } else {
            return
        }

        _ = await WMFImageColorSampler.shared.sampledColor(from: data)
    }

    /// Lets a test wait until all prefetch tasks are complete.
    func waitForAllPrefetchTasks() async {
        for task in tasks {
            await task.value
        }
    }

    deinit {
        tasks.forEach { $0.cancel() }
    }
}
