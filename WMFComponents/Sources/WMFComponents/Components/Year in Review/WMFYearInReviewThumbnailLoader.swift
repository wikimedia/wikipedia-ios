import Foundation
import WMFData

/// Fetches the article thumbnails that a slide binds into its .riv.
@MainActor
final class WMFYearInReviewThumbnailLoader: ObservableObject {

    @Published private(set) var images: [WMFRiveImage: Data] = [:]

    private let fetchThumbnail: @Sendable (WMFYearInReviewSlideViewModel.ArticleThumbnail) async throws -> Data?

    init(fetchThumbnail: @escaping @Sendable (WMFYearInReviewSlideViewModel.ArticleThumbnail) async throws -> Data? = WMFYearInReviewThumbnailLoader.fetchThumbnail) {
        self.fetchThumbnail = fetchThumbnail
    }

    /// An article without a thumbnail, or one that fails to load, is left out.
    func load(_ thumbnails: [WMFRiveImage: WMFYearInReviewSlideViewModel.ArticleThumbnail]) async {
        guard !thumbnails.isEmpty else {
            images = [:]
            return
        }

        let fetchThumbnail = fetchThumbnail
        let loaded = await withTaskGroup(of: (WMFRiveImage, Data?).self) { group in
            for (property, thumbnail) in thumbnails {
                group.addTask {
                    (property, try? await fetchThumbnail(thumbnail))
                }
            }

            var loaded: [WMFRiveImage: Data] = [:]
            for await (property, data) in group {
                if let data {
                    loaded[property] = data
                }
            }
            return loaded
        }

        guard !Task.isCancelled else { return }
        images = loaded
    }

    nonisolated private static func fetchThumbnail(_ thumbnail: WMFYearInReviewSlideViewModel.ArticleThumbnail) async throws -> Data? {
        let summary = try await WMFArticleSummaryDataController.shared.fetchArticleSummary(project: thumbnail.project, title: thumbnail.title)
        guard let thumbnailURL = summary.thumbnailURL else {
            return nil
        }
        return try await WMFImageDataController.shared.fetchImageData(url: thumbnailURL)
    }
}
