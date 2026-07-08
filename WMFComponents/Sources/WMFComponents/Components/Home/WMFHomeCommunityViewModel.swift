import Foundation
import WMFData

public enum WMFCommunityModule {
    case featuredArticle
    case topRead
    case inTheNews
    case onThisDay
    case pictureOfDay
}

public struct WMFCommunityModuleVisibility {
    public var featuredArticle: Bool
    public var topRead: Bool
    public var inTheNews: Bool
    public var onThisDay: Bool
    public var pictureOfDay: Bool
}

public struct WMFHomeCommunityViewModel {

    // MARK: - Nested display types

    public struct TopReadItem {
        public let title: String
        public let displayTitle: String
        public let projectID: String
    }

    public struct NewsItem {
        public let story: String
    }

    public struct OnThisDayItem {
        public let year: Int
        public let yearsAgo: String
        public let text: String
        public let pages: [WMFOnThisDayPage]
        public let projectID: String
    }

    // MARK: - Properties

    public let date: String
    public let featuredArticle: WMFFeedArticle?
    public let topReadItems: [TopReadItem]
    public let newsItems: [NewsItem]
    public let onThisDayItems: [OnThisDayItem]?
    public let pictureOfDay: WMFFeedImageSource?
    public let project: WMFProject

    // MARK: - Hide keys
    // Content-specific cards (Featured Article, Picture of Day) use a title-based key so the same
    // content stays hidden across days. Date-bounded cards use date + project so only that day's
    // instance is hidden and tomorrow's content reappears naturally (mirrors Android's scheme).

    public let featuredArticleHideKey: String?
    public let topReadHideKey: String
    public let inTheNewsHideKey: String
    public let onThisDayHideKey: String
    public let pictureOfDayHideKey: String?

    // MARK: - Init

    public init(response: WMFCommunityResponse, project: WMFProject) {
        let projectID = project.id
        let currentYear = Calendar.current.component(.year, from: Date())

        self.project = project

        let keyDateFormatter = DateFormatter()
        keyDateFormatter.dateFormat = "yyyy-MM-dd"
        let dateKey = keyDateFormatter.string(from: response.date)
        self.featuredArticleHideKey = response.feedResponse.todaysFeaturedArticle?.title.map { "featured_article_\($0)" }
        self.topReadHideKey = "top_read_\(dateKey)_\(projectID)"
        self.inTheNewsHideKey = "in_the_news_\(dateKey)_\(projectID)"
        self.onThisDayHideKey = "on_this_day_\(dateKey)_\(projectID)"
        self.pictureOfDayHideKey = response.feedResponse.image?.thumbnail?.source.map { "picture_of_day_\($0.hashValue)" }

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMMM d, yyyy"
        self.date = dateFormatter.string(from: response.date)
        self.featuredArticle = response.feedResponse.todaysFeaturedArticle

        self.topReadItems = (response.feedResponse.mostRead?.articles ?? [])
            .prefix(5)
            .compactMap { article in
                guard let title = article.title ?? article.normalizedTitle else { return nil }
                let displayTitle = (try? HtmlUtils.stringFromHTML(article.displayTitle ?? title)) ?? title
                return TopReadItem(title: title, displayTitle: displayTitle, projectID: projectID)
            }

        self.newsItems = (response.feedResponse.news ?? [])
            .map { item in
                let story = (try? HtmlUtils.stringFromHTML(item.story ?? "")) ?? item.story ?? ""
                return NewsItem(story: story)
            }

        if let onThisDay = response.onThisDay {
            self.onThisDayItems = onThisDay.events.prefix(2).map { event in
                OnThisDayItem(
                    year: event.year,
                    yearsAgo: "\(currentYear - event.year) years ago",
                    text: event.text,
                    pages: event.pages,
                    projectID: projectID
                )
            }
        } else {
            self.onThisDayItems = nil
        }

        self.pictureOfDay = response.feedResponse.image?.thumbnail
    }
}
