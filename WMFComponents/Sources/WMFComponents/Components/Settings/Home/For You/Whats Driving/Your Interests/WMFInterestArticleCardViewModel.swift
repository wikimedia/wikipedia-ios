import Foundation
import WMFData
import UIKit

@MainActor
final class WMFInterestArticleCardViewModel: ObservableObject, Identifiable {

    // Normalized title used as the stable identifier and for Core Data operations
    let id: String
    let title: String
    let rawTitle: String
    @Published var description: String?
    @Published var uiImage: UIImage?
    @Published var isSelected: Bool

    var thumbnailURL: URL?
    private let summaryFetchInfo: (title: String, project: WMFProject)?
    private var imageTask: Task<Void, Never>?
    private var summaryTask: Task<Void, Never>?

    init(article: WMFRandomArticle, isSelected: Bool = false) {
        self.rawTitle = article.title
        self.id = article.title.normalizedForCoreData
        self.title = article.displayTitle ?? article.title.underscoresToSpaces
        self.description = article.description
        self.thumbnailURL = article.thumbnail?.url
        self.summaryFetchInfo = nil
        self.isSelected = isSelected
    }

    // Used when creating a card from a WMFPageInterest — loads summary on demand
    init(pageInterest: WMFPageInterest, project: WMFProject) {
        self.rawTitle = pageInterest.title
        self.id = pageInterest.title.normalizedForCoreData
        self.title = pageInterest.title.underscoresToSpaces
        self.description = nil
        self.thumbnailURL = nil
        self.summaryFetchInfo = (pageInterest.title, project)
        self.isSelected = true
    }

    // Used when promoting a random article card to a saved interest without a new network fetch
    init(rawTitle: String, displayTitle: String, description: String?, thumbnailURL: URL?, project: WMFProject) {
        self.rawTitle = rawTitle
        self.id = rawTitle.normalizedForCoreData
        self.title = displayTitle
        self.description = description
        self.thumbnailURL = thumbnailURL
        self.summaryFetchInfo = nil
        self.isSelected = true
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
