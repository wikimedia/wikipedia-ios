import Foundation
import WMFData
import UIKit

@MainActor
final class WMFInterestArticleCardViewModel: ObservableObject, Identifiable {

    let id: String
    let title: String
    let project: WMFProject
    @Published var displayTitle: String
    @Published var description: String?
    @Published var uiImage: UIImage?
    @Published var isSelected: Bool

    var thumbnailURL: URL?
    private let needsSummary: Bool
    private var imageTask: Task<Void, Never>?
    private var summaryTask: Task<Void, Never>?

    init(article: WMFRandomArticle, project: WMFProject, isSelected: Bool = false) {
        self.id = article.title.normalizedForCoreData
        self.title = article.title
        self.displayTitle = article.displayTitle ?? article.title.underscoresToSpaces
        self.project = project
        self.description = article.description
        self.thumbnailURL = article.thumbnail?.url
        self.needsSummary = false
        self.isSelected = isSelected
    }

    /// A card known only by title, like a saved interest or a suggestion from reading history.
    /// The description and the image come from the article summary when the card shows.
    init(title: String, project: WMFProject, isSelected: Bool) {
        self.id = title.normalizedForCoreData
        self.title = title
        self.displayTitle = title.underscoresToSpaces
        self.project = project
        self.description = nil
        self.thumbnailURL = nil
        self.needsSummary = true
        self.isSelected = isSelected
    }

    // Used when creating a card from an article search result
    init(searchResult: WMFArticleSearchResult, project: WMFProject, isSelected: Bool = false) {
        self.id = searchResult.title.normalizedForCoreData
        self.title = searchResult.title
        self.displayTitle = searchResult.displayTitle ?? searchResult.title.underscoresToSpaces
        self.project = project
        self.description = searchResult.description
        self.thumbnailURL = searchResult.thumbnailURL
        self.needsSummary = false
        self.isSelected = isSelected
    }

    func loadIfNeeded() {
        if needsSummary {
            loadSummaryAndImage()
        } else {
            loadImageIfNeeded()
        }
    }

    private func loadImageIfNeeded() {
        guard uiImage == nil, let url = thumbnailURL else { return }
        imageTask?.cancel()
        imageTask = Task { [weak self] in
            guard let self else { return }
            guard let data = try? await WMFImageDataController.shared.fetchImageData(url: url),
                  !Task.isCancelled else { return }
            self.uiImage = UIImage(data: data)
        }
    }

    private func loadSummaryAndImage() {
        guard summaryTask == nil else { return }
        let title = title
        let project = project
        summaryTask = Task { [weak self] in
            guard let self else { return }
            guard let summary = try? await WMFArticleSummaryDataController.shared.fetchArticleSummary(project: project, title: title.spacesToUnderscores),
                  !Task.isCancelled else { return }
            self.displayTitle = summary.displayTitle
            self.description = summary.description
            self.thumbnailURL = summary.thumbnailURL
            if let url = summary.thumbnailURL {
                guard let data = try? await WMFImageDataController.shared.fetchImageData(url: url),
                      !Task.isCancelled else { return }
                self.uiImage = UIImage(data: data)
            }
        }
    }

    deinit {
        imageTask?.cancel()
        summaryTask?.cancel()
    }
}
