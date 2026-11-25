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

    /// On iPad, the side of the two columns the Figma puts this module on.
    var isInLeadingColumn: Bool {
        switch self {
        case .featuredArticle, .topRead, .pictureOfDay:
            return true
        case .inTheNews, .onThisDay:
            return false
        }
    }

    /// The module's name, in the language of `languageCode` when the app has a translation for it.
    /// The feed passes the wiki's language, so that the headers match the content below them. The
    /// settings screen passes nil, for the app language.
    public func title(languageCode: String?) -> String {
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

/// What the reader asked to do with an article on a Community card, from a tap, the long-press
/// menu or the Save button. The same actions as the Explore feed's article cards.
public enum WMFCommunityArticleAction: Sendable, Equatable {
    case open
    case openInNewTab
    case openInBackgroundTab
    case save
    case unsave
    case share
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

    /// Spoken after "Picture of the day" on its image, which is a button.
    static var pictureOfTheDayHint: String {
        WMFLocalizedString("home-community-picture-of-the-day-hint", value: "Opens the picture in full screen, with its description and license.", comment: "VoiceOver hint on the Picture of the day image in the Home tab's Community feed. Tapping the image opens it in the image viewer.")
    }

    /// Top read's subtitle on an earlier day, where "today" would be wrong.
    var topReadPastSubtitle: String {
        WMFLocalizedString("home-community-top-read-past-subtitle", languageCode: languageCode, value: "What was trending on Wikipedia that day", comment: "Subtitle of the Top read module in the Home tab's Community feed, for a day before today.")
    }

    /// The link under Top read that opens the day's full list.
    var moreTopRead: String {
        WMFLocalizedString("home-community-more-top-read", languageCode: languageCode, value: "More top read", comment: "Link under the Top read module in the Home tab's Community feed. It opens the full list of the day's most read articles.")
    }

    /// The link under On this day that opens every event of the day.
    var moreOnThisDay: String {
        WMFLocalizedString("home-community-more-on-this-day", languageCode: languageCode, value: "More on this day", comment: "Link under the On this day module in the Home tab's Community feed. It opens the full list of the day's historical events.")
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

    public struct NewsItem {
        public let story: String
        /// The story as the feed sent it, with all its linked articles. A tap opens it in the
        /// news story screen, like Android and the legacy Explore feed.
        public let newsItem: WMFFeedNewsItem
        /// Thumbnail of the article the story is illustrated with, chosen the same way the
        /// explore feed does (see WMFFeedNewsItem.featuredArticle(picturedText:)).
        public let imageURLString: String?
    }

    public struct OnThisDayItem {
        public let year: Int
        public let yearsAgo: String
        public let text: String
        public let pages: [WMFCommunityArticle]

        /// Stable across a refresh of the same day, for SwiftUI identity.
        var id: String { "\(year)|\(text)" }
    }

    // MARK: - Properties

    /// The day and the wiki of this page. Two pages of one feed never share it.
    public let id: String
    /// The day this page is for. Picture of the day opens its gallery for this date.
    public let feedDate: Date
    /// The header above this day's modules, in the app language as on Android: "Today - Mar 23, 2026"
    /// for today, the date alone for an earlier day.
    public let date: String
    let strings: WMFCommunityFeedStrings
    /// True for today's page. Earlier pages word some subtitles in the past tense.
    public let isToday: Bool
    public let featuredArticle: WMFFeedArticle?
    /// The featured article as a row model, for its long-press menu and its saved state.
    public let featuredArticleItem: WMFCommunityArticle?
    /// The first five most read articles, which the module shows.
    public let topReadItems: [WMFCommunityArticle]
    /// Every most read article of the day, for "More top read".
    public let allTopReadTitles: [String]
    public let newsItems: [NewsItem]
    public let onThisDayItems: [OnThisDayItem]?
    public let pictureOfDay: WMFFeedImageSource?
    /// The picture's description, shown over the image like the Explore feed does.
    public let pictureOfDayCaption: String?
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

        let formattedDate = DateFormatter.wmfShortMonthDayYearDateFormatter.string(from: response.date)
        let isToday = Calendar.current.isDate(response.date, inSameDayAs: now)
        self.isToday = isToday
        self.date = isToday ? WMFCommunityFeedStrings.todayDateHeader(formattedDate) : formattedDate
        self.featuredArticle = response.feedResponse.todaysFeaturedArticle
        self.featuredArticleItem = response.feedResponse.todaysFeaturedArticle.flatMap(WMFCommunityArticle.init(feedArticle:))

        let mostRead = (response.feedResponse.mostRead?.articles ?? []).compactMap(WMFCommunityArticle.init(mostReadArticle:))
        self.topReadItems = Array(mostRead.prefix(5))
        self.allTopReadTitles = mostRead.map(\.title)

        self.newsItems = (response.feedResponse.news ?? [])
            .map { item in
                let story = (try? HtmlUtils.stringFromHTML(item.story ?? "")) ?? item.story ?? ""
                let featured = item.featuredArticle(picturedText: picturedText)
                return NewsItem(story: story, newsItem: item, imageURLString: featured?.thumbnail?.source)
            }

        // Like Android, the module shows the first two events the wiki's editors picked for the day.
        // A wiki whose feed has no picks falls back to the newest events of the full list. A wiki
        // without On this day content has neither, and the module is hidden.
        let pickedEvents = response.feedResponse.onThisDay ?? []
        let events = pickedEvents.isEmpty ? (response.onThisDay?.events ?? []) : pickedEvents
        if events.isEmpty {
            self.onThisDayItems = nil
        } else {
            self.onThisDayItems = events.prefix(2).map { event in
                OnThisDayItem(
                    year: event.year,
                    yearsAgo: Self.yearsAgo(currentYear - event.year, languageCode: project.languageCode),
                    text: event.text,
                    pages: event.pages.map(WMFCommunityArticle.init(onThisDayPage:))
                )
            }
        }

        self.pictureOfDay = response.feedResponse.image?.thumbnail
        let caption = response.feedResponse.image?.description?.text
            ?? response.feedResponse.image?.description?.html.flatMap { try? HtmlUtils.stringFromHTML($0) }
        let trimmedCaption = caption?.trimmingCharacters(in: .whitespacesAndNewlines)
        self.pictureOfDayCaption = (trimmedCaption?.isEmpty ?? true) ? nil : trimmedCaption
    }

    /// The line under a module's name. Top read says "today" in its subtitle, so an earlier day
    /// gets its own wording.
    func subtitle(for module: WMFCommunityModule) -> String {
        if module == .topRead, !isToday {
            return strings.topReadPastSubtitle
        }
        return module.subtitle(languageCode: strings.languageCode)
    }

    /// "This year", "Last year", "6 years ago", in the wiki's language. Uses the app's own plural
    /// string, formatted with the wiki's locale so its plural rules apply, the way the legacy On
    /// this day card does.
    static func yearsAgo(_ years: Int, languageCode: String?) -> String {
        let locale = languageCode.map { Locale(identifier: $0) } ?? .current
        return String(format: CommonStrings.yearsAgo(languageCode: languageCode), locale: locale, years)
    }

    /// The position in the day's full On this day list of an event tapped on the card. The card
    /// shows the editors' picks, which the full list words differently, so an event without an
    /// exact match opens at the first event of its year, as Android does.
    public static func onThisDayEventIndex(year: Int, text: String, in events: [WMFOnThisDayEvent]) -> Int? {
        events.firstIndex { $0.year == year && $0.text == text }
            ?? events.firstIndex { $0.year == year }
    }

    // MARK: - Layout

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

    /// Splits a day's modules into the two iPad columns. A full day follows the Figma: the
    /// image-led modules on the leading side, the story modules on the trailing side.
    ///
    /// Many wikis leave modules out (most have no In the news, and small ones often have only Top
    /// read and Picture of the day), so the split adapts to what the day has:
    /// - One module: it gets the leading column alone. The view then draws the day at full width.
    /// - One side empty: the modules are shared out between both columns in feed order, so half
    ///   the screen is never blank.
    /// - Sides two or more modules apart: the longer side gives its last modules to the shorter
    ///   one until they differ by at most one.
    /// Each column keeps feed order, and the leading column is never empty.
    static func columns(for modules: [WMFCommunityModule]) -> (leading: [WMFCommunityModule], trailing: [WMFCommunityModule]) {
        guard modules.count > 1 else { return (modules, []) }

        var leading = modules.filter(\.isInLeadingColumn)
        var trailing = modules.filter { !$0.isInLeadingColumn }

        if leading.isEmpty || trailing.isEmpty {
            let half = (modules.count + 1) / 2
            return (Array(modules.prefix(half)), Array(modules.dropFirst(half)))
        }

        while leading.count - trailing.count >= 2, let moved = leading.popLast() {
            trailing.append(moved)
        }
        while trailing.count - leading.count >= 2, let moved = trailing.popLast() {
            leading.append(moved)
        }
        return (leading, trailing)
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

// MARK: - Article

/// An article that a Community card links to, with what its row, its long-press preview and the
/// coordinator need. Everything comes from the feed response, so a row needs no extra request.
public struct WMFCommunityArticle: Sendable, Equatable {
    /// The database title, which opens the article.
    public let title: String
    /// The display title. It can contain HTML, such as `<i>` for a work's title.
    public let displayTitleHTML: String
    /// The display title without its HTML, for VoiceOver and the preview.
    public let plainTitle: String
    public let description: String?
    public let extract: String?
    public let thumbnailURL: URL?

    init(title: String, displayTitleHTML: String?, normalizedTitle: String?, description: String?, extract: String?, thumbnailURL: URL?) {
        let fallbackTitle = normalizedTitle ?? title.replacingOccurrences(of: "_", with: " ")
        let html = displayTitleHTML ?? fallbackTitle
        self.title = title
        self.displayTitleHTML = html
        self.plainTitle = (try? HtmlUtils.stringFromHTML(html)) ?? fallbackTitle
        self.description = description
        self.extract = extract
        self.thumbnailURL = thumbnailURL
    }

    init?(feedArticle: WMFFeedArticle) {
        guard let title = feedArticle.title ?? feedArticle.normalizedTitle else { return nil }
        self.init(title: title, displayTitleHTML: feedArticle.displayTitle, normalizedTitle: feedArticle.normalizedTitle, description: feedArticle.description, extract: feedArticle.extract, thumbnailURL: feedArticle.thumbnail?.source.flatMap(URL.init(string:)))
    }

    init?(mostReadArticle: WMFFeedMostReadArticle) {
        guard let title = mostReadArticle.title ?? mostReadArticle.normalizedTitle else { return nil }
        self.init(title: title, displayTitleHTML: mostReadArticle.displayTitle, normalizedTitle: mostReadArticle.normalizedTitle, description: mostReadArticle.description, extract: mostReadArticle.extract, thumbnailURL: mostReadArticle.thumbnail?.source.flatMap(URL.init(string:)))
    }

    init(onThisDayPage page: WMFOnThisDayPage) {
        self.init(title: page.title, displayTitleHTML: page.displayTitle, normalizedTitle: page.normalizedTitle, description: page.description, extract: page.extract, thumbnailURL: page.thumbnail?.source)
    }
}
