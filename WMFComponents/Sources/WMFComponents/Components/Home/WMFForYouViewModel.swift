import Foundation
import UIKit
import WMFData

@MainActor
public final class WMFForYouViewModel: ObservableObject {

    @Published public var topicPages: [WMFForYouTopicPageViewModel] = []

    public init(response: WMFForYouResponse) {
        self.topicPages = response.interestTopicRandomArticles.map {
            WMFForYouTopicPageViewModel(topicArticles: $0)
        }
    }
}

@MainActor
public final class WMFForYouTopicPageViewModel: ObservableObject, Identifiable {

    public let id = UUID()
    public let topicName: String
    public let articleViewModels: [WMFForYouArticleCardViewModel]

    public init(topicArticles: WMFForYouInterestTopicRandomArticles) {
        self.topicName = topicArticles.topic.displayName
        self.articleViewModels = topicArticles.articles.map {
            WMFForYouArticleCardViewModel(article: $0)
        }
    }
}

@MainActor
public final class WMFForYouArticleCardViewModel: ObservableObject, Identifiable {

    public let id = UUID()
    public let title: String
    public let project: WMFProject
    @Published public var description: String?
    @Published public var uiImage: UIImage?

    private var loadTask: Task<Void, Never>?

    public init(article: WMFForYouArticle) {
        self.title = article.title
        self.project = article.project
    }

    public func load() {
        guard loadTask == nil else { return }
        loadTask = Task { [weak self] in
            guard let self else { return }
            guard let summary = try? await WMFArticleSummaryDataController.shared.fetchArticleSummary(project: project, title: title) else { return }
            self.description = summary.description
            guard let thumbnailURL = summary.thumbnailURL else { return }
            guard let data = try? await WMFImageDataController.shared.fetchImageData(url: thumbnailURL) else { return }
            self.uiImage = UIImage(data: data)
        }
    }

    deinit {
        loadTask?.cancel()
    }
}
