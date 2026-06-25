import Foundation
import UIKit
import WMFData

@MainActor
public final class WMFForYouViewModel: ObservableObject {

    @Published public var pages: [WMFForYouPageViewModel] = []

    public init(response: WMFForYouResponse) {
        let topicPages = response.interestTopicRandomArticles.map {
            WMFForYouPageViewModel(headerLabel: "Interest Topic: \($0.topic.displayName)", articles: $0.articles)
        }
        let relatedPages = response.interestPageRelatedArticles.map {
            WMFForYouPageViewModel(headerLabel: "Interest Article: \($0.pageInterest.title)", articles: $0.articles)
        }
        let becauseYouReadPage: [WMFForYouPageViewModel] = response.becauseYouReadArticles.map {
            [WMFForYouPageViewModel(headerLabel: "Because you read: \($0.recentlyRead.title)", articles: $0.articles)]
        } ?? []
        let continueReadingPage: [WMFForYouPageViewModel] = response.continueReadingArticles.map { continueReading in
            let continueCard = WMFForYouArticleCardViewModel(
                article: continueReading.continueReadingArticle,
                headerLabel: "Continue reading: \(continueReading.continueReadingArticle.title)"
            )
            let savedCards = continueReading.savedArticles.map {
                WMFForYouArticleCardViewModel(article: $0, headerLabel: "Saved article: \($0.title)")
            }
            return [WMFForYouPageViewModel(articleViewModels: [continueCard] + savedCards)]
        } ?? []
        self.pages = topicPages + relatedPages + becauseYouReadPage + continueReadingPage
    }
}

@MainActor
public final class WMFForYouPageViewModel: ObservableObject, Identifiable {

    public let id = UUID()
    public let articleViewModels: [WMFForYouArticleCardViewModel]

    public init(headerLabel: String, articles: [WMFForYouArticle]) {
        self.articleViewModels = articles.map {
            WMFForYouArticleCardViewModel(article: $0, headerLabel: headerLabel)
        }
    }

    public init(articleViewModels: [WMFForYouArticleCardViewModel]) {
        self.articleViewModels = articleViewModels
    }
}

@MainActor
public final class WMFForYouArticleCardViewModel: ObservableObject, Identifiable {

    public let id = UUID()
    public let headerLabel: String
    public let title: String
    public let project: WMFProject
    @Published public var description: String?
    @Published public var uiImage: UIImage?

    private var loadTask: Task<Void, Never>?

    public init(article: WMFForYouArticle, headerLabel: String) {
        self.headerLabel = headerLabel
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
