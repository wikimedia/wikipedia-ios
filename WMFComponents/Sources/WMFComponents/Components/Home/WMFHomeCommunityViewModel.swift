import Foundation
import WMFData
import WMFNativeLocalizations

/// The Community feed modules, in the order the feed shows them on a phone. The order follows the
/// ticket (T427579) and the Android app; Did you know will go between Top read and In the news.
public enum WMFCommunityModule: CaseIterable, Sendable {
    case featuredArticle
    case topRead
    case inTheNews
    case onThisDay
    case pictureOfDay


    /// The module's name, in the language of `languageCode` when the app has a translation for it.
    /// The feed passes the wiki's language, so that the headers match the content below them. The
    /// settings screen passes nil, for the app language.
    func title(languageCode: String?) -> String {
        switch self {
        case .featuredArticle:
            return WMFLocalizedString("home-feed-modules-featured-article-title", languageCode: languageCode, value: "Featured article", comment: "Title of the Featured article module, in the Community feed and in its settings.")
        case .topRead:
            return WMFLocalizedString("home-feed-modules-top-read-title", languageCode: languageCode, value: "Top read", comment: "Title of the Top read module, in the Community feed and in its settings.")
        case .inTheNews:
            return WMFLocalizedString("home-feed-modules-in-the-news-title", languageCode: languageCode, value: "In the news", comment: "Title of the In the news module, in the Community feed and in its settings.")
        case .onThisDay:
            return WMFLocalizedString("home-feed-modules-on-this-day-title", languageCode: languageCode, value: "On this day", comment: "Title of the On this day module, in the Community feed and in its settings.")
        case .pictureOfDay:
            return WMFLocalizedString("home-feed-modules-picture-of-the-day-title", languageCode: languageCode, value: "Picture of the day", comment: "Title of the Picture of the day module, in the Community feed and in its settings.")
        }
    }

    /// The line under the module's name. Same language rule as `title(languageCode:)`.
    func subtitle(languageCode: String?) -> String {
        switch self {
        case .featuredArticle:
            return WMFLocalizedString("home-feed-modules-featured-article-subtitle", languageCode: languageCode, value: "Featured articles are some of the highest-quality articles on Wikipedia, selected daily by editors", comment: "Subtitle describing the Featured article module, in the Community feed and in its settings.")
        case .topRead:
            return WMFLocalizedString("home-feed-modules-top-read-subtitle", languageCode: languageCode, value: "What is trending today on Wikipedia", comment: "Subtitle describing the Top read module, in the Community feed and in its settings.")
        case .inTheNews:
            return WMFLocalizedString("home-feed-modules-in-the-news-subtitle", languageCode: languageCode, value: "Articles that have been substantially updated to reflect recent or current events of wide interest", comment: "Subtitle describing the In the news module, in the Community feed and in its settings.")
        case .onThisDay:
            return WMFLocalizedString("home-feed-modules-on-this-day-subtitle", languageCode: languageCode, value: "Discover historical events from this day", comment: "Subtitle describing the On this day module, in the Community feed and in its settings.")
        case .pictureOfDay:
            return WMFLocalizedString("home-feed-modules-picture-of-the-day-subtitle", languageCode: languageCode, value: "Daily images on Wikimedia Commons, selected by volunteer contributors", comment: "Subtitle describing the Picture of the day module, in the Community feed and in its settings.")
        }
    }
}

public struct WMFCommunityModuleVisibility: Equatable {
    public var featuredArticle: Bool
    public var topRead: Bool
    public var inTheNews: Bool
    public var onThisDay: Bool
    public var pictureOfDay: Bool

    func isOn(_ module: WMFCommunityModule) -> Bool {
        switch module {
        case .featuredArticle: return featuredArticle
        case .topRead: return topRead
        case .inTheNews: return inTheNews
        case .onThisDay: return onThisDay
        case .pictureOfDay: return pictureOfDay
        }
    }
}

/// The text the Community feed draws around its modules. It is in the language of the wiki the feed
/// comes from, like the content, when the app has a translation for that language.
struct WMFCommunityFeedStrings {
    let languageCode: String?

    var disclaimer: String {
        WMFLocalizedString("home-community-disclaimer", languageCode: languageCode, value: "Content and resources selected by and about the Wikimedia community.", comment: "Note at the top of the Home tab's Community feed, explaining who chose the content below it.")
    }

    var seePastContent: String {
        WMFLocalizedString("home-community-see-past-content", languageCode: languageCode, value: "See past community content", comment: "Button at the bottom of the Community feed that loads content from previous days.")
    }

    /// The date above today's modules, e.g. "Today - Mar 23, 2026". Like Android, this one header
    /// follows the app language, not the wiki's.
    static func todayDateHeader(_ formattedDate: String) -> String {
        let format = WMFLocalizedString("home-community-today-date-header", value: "Today - %1$@", comment: "Header above today's modules in the Home tab's Community feed. %1$@ is replaced with today's date, e.g. \"Today - Mar 23, 2026\".")
        return String.localizedStringWithFormat(format, formattedDate)
    }
}

public struct WMFHomeCommunityViewModel: Identifiable {

    // MARK: - Nested display types

    public struct TopReadItem {
        public let title: String
        public let displayTitle: String
        public let projectID: String
    }

    public struct NewsItem {
        public let story: String
        /// The article the story is about, opened when the reader taps the story.
        public let articleTitle: String?
        /// Thumbnail of the article the story is illustrated with, chosen the same way the
        /// explore feed does (see WMFFeedNewsItem.featuredArticle(picturedText:)).
        public let imageURLString: String?
    }

    public struct OnThisDayItem {
        public let year: Int
        public let yearsAgo: String
        public let text: String
        public let pages: [WMFOnThisDayPage]
        public let projectID: String
    }

    // MARK: - Properties

    /// The day and the wiki of this page. Two pages of one feed never share it.
    public let id: String
    /// The day this page is for. Picture of the day opens its gallery for this date.
    public let feedDate: Date
    /// The header above this day's modules, in the wiki's language: "Today - Mar 23, 2026" for
    /// today, the date alone for an earlier day.
    public let date: String
    let strings: WMFCommunityFeedStrings
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

    public init(response: WMFCommunityResponse, project: WMFProject, now: Date = Date()) {
        let projectID = project.id

        // Localized in the wiki's language, not the app UI's: it is matched against the story
        // HTML, which comes from that wiki.
        let picturedText = WMFLocalizedString("pictured", languageCode: project.languageCode, value: "pictured", comment: "Indicates the person or item is pictured (as in a news story).")
        let currentYear = Calendar.current.component(.year, from: now)

        self.project = project
        self.feedDate = response.date
        self.strings = WMFCommunityFeedStrings(languageCode: project.languageCode)

        let keyDateFormatter = DateFormatter()
        keyDateFormatter.locale = Locale(identifier: "en_US_POSIX")
        keyDateFormatter.dateFormat = "yyyy-MM-dd"
        let dateKey = keyDateFormatter.string(from: response.date)
        self.id = "\(projectID)_\(dateKey)"
        self.featuredArticleHideKey = response.feedResponse.todaysFeaturedArticle?.title.map { "featured_article_\($0)" }
        self.topReadHideKey = "top_read_\(dateKey)_\(projectID)"
        self.inTheNewsHideKey = "in_the_news_\(dateKey)_\(projectID)"
        self.onThisDayHideKey = "on_this_day_\(dateKey)_\(projectID)"
        // The file title is stable across launches. `String.hashValue` is not: it is seeded per
        // process, so a picture hidden with it came back on the next launch.
        let pictureOfDayID = response.feedResponse.image?.title ?? response.feedResponse.image?.thumbnail?.source
        self.pictureOfDayHideKey = pictureOfDayID.map { "picture_of_day_\($0)" }

        let formattedDate = DateFormatter.wmfMediumDateFormatter(languageCode: nil).string(from: response.date)
        self.date = Calendar.current.isDate(response.date, inSameDayAs: now) ? WMFCommunityFeedStrings.todayDateHeader(formattedDate) : formattedDate
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
                let featured = item.featuredArticle(picturedText: picturedText)
                return NewsItem(story: story, articleTitle: featured?.title, imageURLString: featured?.thumbnail?.source)
            }

        // A wiki without On this day content answers with no events. The module is hidden then,
        // like the modules the feed response leaves out.
        if let onThisDay = response.onThisDay, !onThisDay.events.isEmpty {
            self.onThisDayItems = onThisDay.events.prefix(2).map { event in
                OnThisDayItem(
                    year: event.year,
                    yearsAgo: Self.yearsAgo(currentYear - event.year, languageCode: project.languageCode),
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

    /// "This year", "Last year", "6 years ago", in the wiki's language. Uses the app's own plural
    /// string, formatted with the wiki's locale so its plural rules apply, the way the legacy On
    /// this day card does.
    static func yearsAgo(_ years: Int, languageCode: String?) -> String {
        let locale = languageCode.map { Locale(identifier: $0) } ?? .current
        return String(format: CommonStrings.yearsAgo(languageCode: languageCode), locale: locale, years)
    }

    // MARK: - Layout

    /// Feed content of a right-to-left wiki is laid out right to left, whatever the app language.
    var isRTL: Bool {
        project.isRTL
    }

    /// The modules this page shows, in feed order. A module is left out when the reader turned it
    /// off, hid this card, or the wiki has no content for it that day.
    func visibleModules(visibility: WMFCommunityModuleVisibility, hiddenCardKeys: Set<String>) -> [WMFCommunityModule] {
        WMFCommunityModule.allCases.filter { module in
            guard visibility.isOn(module) else { return false }
            switch module {
            case .featuredArticle:
                return featuredArticle != nil && !isHidden(featuredArticleHideKey, in: hiddenCardKeys)
            case .topRead:
                return !topReadItems.isEmpty && !hiddenCardKeys.contains(topReadHideKey)
            case .inTheNews:
                return !newsItems.isEmpty && !hiddenCardKeys.contains(inTheNewsHideKey)
            case .onThisDay:
                return !(onThisDayItems ?? []).isEmpty && !hiddenCardKeys.contains(onThisDayHideKey)
            case .pictureOfDay:
                return pictureOfDay != nil && !isHidden(pictureOfDayHideKey, in: hiddenCardKeys)
            }
        }
    }

    // MARK: - iPad columns

    /// Splits a day's modules into the two iPad columns so that each holds about half the day's
    /// height. Modules keep their feed order: each one goes to whichever column is shorter so far,
    /// the leading one on a tie; the first module always starts the leading column. `leadingOffset` is the height already above the leading column's
    /// first module, such as the disclaimer and the date on the first day.
    func columns(for modules: [WMFCommunityModule], leadingOffset: Double = 0) -> (leading: [WMFCommunityModule], trailing: [WMFCommunityModule]) {
        var leading: [WMFCommunityModule] = []
        var trailing: [WMFCommunityModule] = []
        var leadingHeight = leadingOffset
        var trailingHeight = 0.0
        for module in modules {
            let height = estimatedHeight(of: module)
            // The first module always starts the leading column, under the date.
            if leading.isEmpty || leadingHeight <= trailingHeight {
                leading.append(module)
                leadingHeight += height
            } else {
                trailing.append(module)
                trailingHeight += height
            }
        }
        return (leading, trailing)
    }

    /// A rough height in points of a module at the default text size, header included. It only
    /// needs to be good enough to balance the columns, not to lay them out.
    func estimatedHeight(of module: WMFCommunityModule) -> Double {
        let header = 90.0
        switch module {
        case .featuredArticle:
            return header + 200 + 160
        case .topRead:
            return header + Double(topReadItems.count) * 75
        case .inTheNews:
            return header + 216
        case .onThisDay:
            let events = onThisDayItems ?? []
            return header + events.reduce(0) { total, event in
                total + 170 + (event.pages.isEmpty ? 0 : 80)
            }
        case .pictureOfDay:
            return header + 300
        }
    }

    func hideKey(for module: WMFCommunityModule) -> String? {
        switch module {
        case .featuredArticle: return featuredArticleHideKey
        case .topRead: return topReadHideKey
        case .inTheNews: return inTheNewsHideKey
        case .onThisDay: return onThisDayHideKey
        case .pictureOfDay: return pictureOfDayHideKey
        }
    }

    private func isHidden(_ key: String?, in hiddenCardKeys: Set<String>) -> Bool {
        guard let key else { return false }
        return hiddenCardKeys.contains(key)
    }
}
