import Foundation
import UIKit
import WMFData

@MainActor
public final class WMFTrendingCountryViewModel: ObservableObject {

    public struct LocalizedStrings {
        public let loadingMessage: String
        public let noArticlesMessage: String

        public init(loadingMessage: String, noArticlesMessage: String) {
            self.loadingMessage = loadingMessage
            self.noArticlesMessage = noArticlesMessage
        }
    }

    @Published public var articleRows: [WMFTrendingViewModel.ArticleRowViewModel] = []
    @Published public var isLoading: Bool = false

    public let countryName: String
    public let localizedStrings: LocalizedStrings
    public var onTapArticle: ((String, WMFProject) -> Void)?

    private let countryCode: String
    private let languageCode: String
    private let dataController: WMFTrendingDataController
    private var loadTask: Task<Void, Never>?

    public init(
        country: WMFTrendingCountryAnnotation,
        localizedStrings: LocalizedStrings,
        dataController: WMFTrendingDataController = WMFTrendingDataController.shared
    ) {
        self.countryName = country.name
        self.countryCode = country.id
        self.languageCode = country.languageCode
        self.localizedStrings = localizedStrings
        self.dataController = dataController
    }

    deinit {
        loadTask?.cancel()
    }

    public func load() {
        loadTask?.cancel()
        loadTask = Task { [weak self] in
            await self?.performLoad()
        }
    }

    private func performLoad() async {
        isLoading = true
        articleRows = []
        do {
            let articles = try await dataController.fetchTrendingByCountry(countryName, languageCode: languageCode)
            articleRows = articles.map { article in
                let project = WMFProject.wikipedia(WMFLanguage(languageCode: article.project, languageVariantCode: nil))
                return WMFTrendingViewModel.ArticleRowViewModel(id: article.id, title: article.displayTitle, project: project)
            }
            await fetchSummaries()
        } catch {
            // Show empty state on error
        }
        isLoading = false
    }

    private func fetchSummaries() async {
        for i in articleRows.indices {
            guard !Task.isCancelled else { return }
            let row = articleRows[i]
            do {
                let summary = try await WMFArticleSummaryDataController.shared.fetchArticleSummary(
                    project: row.project,
                    title: row.title.replacingOccurrences(of: " ", with: "_")
                )
                articleRows[i].description = summary.description
                articleRows[i].thumbnailURLString = summary.thumbnailURL?.absoluteString
                if let thumbnailURL = summary.thumbnailURL {
                    let imageData = try await WMFImageDataController.shared.fetchImageData(url: thumbnailURL)
                    articleRows[i].uiImage = UIImage(data: imageData)
                }
            } catch {
                // Silently skip missing summaries
            }
        }
    }
}
