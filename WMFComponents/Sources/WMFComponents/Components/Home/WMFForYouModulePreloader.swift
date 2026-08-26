import Foundation
import WMFData

/// Loads the data for the module that comes after the one on the screen.
@MainActor
final class WMFForYouModulePreloader {
    
    private nonisolated struct CardInput: Sendable {
        let project: WMFProject
        let title: String
    }

    private let summaryDataController: WMFArticleSummaryDataControlling & Sendable

    private let preloadsImages: Bool

    private var preloadedPageIDs: Set<UUID> = []
    private var tasks: [Task<Void, Never>] = []

    init(
        summaryDataController: WMFArticleSummaryDataControlling & Sendable = WMFArticleSummaryDataController.shared,
        preloadsImages: Bool = true
    ) {
        self.summaryDataController = summaryDataController
        self.preloadsImages = preloadsImages
    }

    func preloadInitialModules(in pages: [WMFForYouPageViewModel], hiddenCardKeys: Set<String> = []) {
        preload(pages: Array(pages.prefix(2)), hiddenCardKeys: hiddenCardKeys)
    }

    func preloadModule(after moduleID: UUID?, in pages: [WMFForYouPageViewModel], hiddenCardKeys: Set<String> = []) {
        guard let moduleID,
              let index = pages.firstIndex(where: { $0.id == moduleID }),
              index + 1 < pages.count else {
            return
        }
        preload(pages: [pages[index + 1]], hiddenCardKeys: hiddenCardKeys)
    }

    private func preload(pages: [WMFForYouPageViewModel], hiddenCardKeys: Set<String>) {
        for page in pages {
            guard preloadedPageIDs.insert(page.id).inserted else { continue }

            let cards = page.articleViewModels
                .filter { !hiddenCardKeys.contains($0.cardUniqueKey) }
                .map { CardInput(project: $0.project, title: $0.title) }
            guard !cards.isEmpty else { continue }

            let summaryDataController = self.summaryDataController
            let preloadsImages = self.preloadsImages
            let task = Task {
                await withTaskGroup(of: Void.self) { group in
                    for card in cards {
                        group.addTask {
                            await Self.preloadCard(card, summaryDataController: summaryDataController, preloadsImages: preloadsImages)
                        }
                    }
                }
            }
            tasks.append(task)
        }
    }

    /// Does the same fetches as `WMFForYouArticleCardViewModel.load()`, in the same sequence. Each
    /// URL and cache key must be equal to what the card requests.
    private nonisolated static func preloadCard(
        _ card: CardInput,
        summaryDataController: WMFArticleSummaryDataControlling & Sendable,
        preloadsImages: Bool
    ) async {
        guard let summary = try? await summaryDataController.fetchArticleSummary(project: card.project, title: card.title) else {
            return
        }
        guard preloadsImages, let thumbnailURL = summary.thumbnailURL else {
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

    /// Lets a test wait until all preload tasks are complete.
    func waitForAllPreloadTasks() async {
        for task in tasks {
            await task.value
        }
    }

    deinit {
        tasks.forEach { $0.cancel() }
    }
}
