import Foundation
import WMFData
import UIKit

@MainActor
final class WMFInterestArticleCardViewModel: ObservableObject, Identifiable {

    let id: String
    let title: String
    let project: WMFProject
    @Published var description: String?
    @Published var uiImage: UIImage?
    @Published var isSelected: Bool

    var thumbnailURL: URL?
    private let summaryFetchInfo: (title: String, project: WMFProject)?
    private var imageTask: Task<Void, Never>?
    private var summaryTask: Task<Void, Never>?

    init(article: WMFRandomArticle, project: WMFProject, isSelected: Bool = false) {
        self.id = article.title
        self.title = article.displayTitle ?? article.title.underscoresToSpaces
        self.project = project
        self.description = article.description
        self.thumbnailURL = article.thumbnail?.url
        self.summaryFetchInfo = nil
        self.isSelected = isSelected
    }

    // Used when creating a card from a WMFPageInterest — loads summary on demand
    init(pageInterest: WMFPageInterest, project: WMFProject) {
        self.id = pageInterest.title
        self.title = pageInterest.title.underscoresToSpaces
        self.project = project
        self.description = nil
        self.thumbnailURL = nil
        self.summaryFetchInfo = (pageInterest.title, project)
        self.isSelected = true
    }

    // Used when creating a card from an article search result
    init(searchResult: WMFArticleSearchResult, project: WMFProject, isSelected: Bool = false) {
        self.id = searchResult.title
        self.title = searchResult.displayTitle ?? searchResult.title.underscoresToSpaces
        self.project = project
        self.description = searchResult.description
        self.thumbnailURL = searchResult.thumbnailURL
        self.summaryFetchInfo = nil
        self.isSelected = isSelected
    }

    func loadIfNeeded() {
        if let info = summaryFetchInfo {
            loadSummaryAndImage(title: info.title, project: info.project)
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

    private func loadSummaryAndImage(title: String, project: WMFProject) {
        guard summaryTask == nil else { return }
        summaryTask = Task { [weak self] in
            guard let self else { return }
            guard let summary = try? await WMFArticleSummaryDataController.shared.fetchArticleSummary(project: project, title: title.spacesToUnderscores),
                  !Task.isCancelled else { return }
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
