import Foundation
import UIKit
import WMFData

// MARK: - Module types and visibility

public enum WMFForYouModule {
    case basedOnInterests
    case becauseYouRead
    case continueReading
}

public struct WMFForYouModuleVisibility {
    public var basedOnInterests: Bool
    public var becauseYouRead: Bool
    public var continueReading: Bool

    func isVisible(_ module: WMFForYouModule) -> Bool {
        switch module {
        case .basedOnInterests: return basedOnInterests
        case .becauseYouRead: return becauseYouRead
        case .continueReading: return continueReading
        }
    }
}

// MARK: - View models

@MainActor
public final class WMFForYouViewModel: ObservableObject {

    @Published public var pages: [WMFForYouPageViewModel] = []

    public init(response: WMFForYouResponse) {
        let topicPages = response.interestTopicRandomArticles.map {
            WMFForYouPageViewModel(module: .basedOnInterests, headerLabel: "Interest Topic: \($0.topic.displayName)", articles: $0.articles)
        }
        let relatedPages = response.interestPageRelatedArticles.map {
            WMFForYouPageViewModel(module: .basedOnInterests, headerLabel: "Interest Article: \($0.pageInterest.title)", articles: $0.articles)
        }
        let becauseYouReadPage: [WMFForYouPageViewModel] = response.becauseYouReadArticles.map {
            [WMFForYouPageViewModel(module: .becauseYouRead, headerLabel: "Because you read: \($0.recentlyRead.title)", articles: $0.articles)]
        } ?? []
        let continueReadingPage: [WMFForYouPageViewModel] = response.continueReadingArticles.map { continueReading in
            let continueCard = WMFForYouArticleCardViewModel(
                article: continueReading.continueReadingArticle,
                headerLabel: "Continue reading: \(continueReading.continueReadingArticle.title)"
            )
            let savedCards = continueReading.savedArticles.map {
                WMFForYouArticleCardViewModel(article: $0, headerLabel: "Saved article: \($0.title)")
            }
            return [WMFForYouPageViewModel(module: .continueReading, articleViewModels: [continueCard] + savedCards)]
        } ?? []
        self.pages = topicPages + relatedPages + becauseYouReadPage + continueReadingPage
    }
}

@MainActor
public final class WMFForYouPageViewModel: ObservableObject, Identifiable {

    public let id = UUID()
    public let module: WMFForYouModule
    public let articleViewModels: [WMFForYouArticleCardViewModel]

    public init(module: WMFForYouModule, headerLabel: String, articles: [WMFForYouArticle]) {
        self.module = module
        self.articleViewModels = articles.map {
            WMFForYouArticleCardViewModel(article: $0, headerLabel: headerLabel)
        }
    }

    public init(module: WMFForYouModule, articleViewModels: [WMFForYouArticleCardViewModel]) {
        self.module = module
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

    public let hideKey: String

    public init(article: WMFForYouArticle, headerLabel: String) {
        self.headerLabel = headerLabel
        self.title = article.title
        self.project = article.project
        self.hideKey = "for_you_\(article.project.id)_\(article.title)"
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
