import Foundation
import WMFData

/// The most-read articles of one day.
@objc(WMFFeedTopReadResponse)
@objcMembers
public final class WMFFeedTopReadResponse: NSObject {

    public let date: Date?
    public let articlePreviews: [WMFFeedTopReadArticlePreview]?

    public init(date: Date?, articlePreviews: [WMFFeedTopReadArticlePreview]?) {
        self.date = date
        self.articlePreviews = articlePreviews
        super.init()
    }

    /// Create the bridge object from the WMFData model.
    public convenience init(mostRead: WMFFeedMostRead, languageVariantCode: String?) {
        let date = mostRead.date.flatMap { DateFormatter.wmf_yearMonthDayZ().date(from: $0) }
        let previews = (mostRead.articles ?? []).compactMap { WMFFeedTopReadArticlePreview(mostReadArticle: $0, languageVariantCode: languageVariantCode) }
        self.init(date: date, articlePreviews: previews)
    }
}

/// The feed content of one day.
///
/// This class is a temporary bridge between the WMFData feed response and the Explore feed content source.
/// Remove this class when the Explore feed is removed.
@objc(WMFFeedDayResponse)
@objcMembers
public final class WMFFeedDayResponse: NSObject {

    /// The number of seconds that the feed content stays fresh.
    public var maxAge: Int
    public let featuredArticle: WMFFeedArticlePreview?
    public let topRead: WMFFeedTopReadResponse?
    public let pictureOfTheDay: WMFFeedImage?
    public let newsStories: [WMFFeedNewsStory]?

    public init(maxAge: Int, featuredArticle: WMFFeedArticlePreview?, topRead: WMFFeedTopReadResponse?, pictureOfTheDay: WMFFeedImage?, newsStories: [WMFFeedNewsStory]?) {
        self.maxAge = maxAge
        self.featuredArticle = featuredArticle
        self.topRead = topRead
        self.pictureOfTheDay = pictureOfTheDay
        self.newsStories = newsStories
        super.init()
    }

    /// Create the bridge object from the WMFData model.
    public convenience init(response: WMFFeedAPIResponse, maxAge: Int, languageVariantCode: String?) {
        self.init(
            maxAge: maxAge,
            featuredArticle: response.todaysFeaturedArticle.flatMap { WMFFeedArticlePreview(article: $0, languageVariantCode: languageVariantCode) },
            topRead: response.mostRead.map { WMFFeedTopReadResponse(mostRead: $0, languageVariantCode: languageVariantCode) },
            pictureOfTheDay: response.image.flatMap { WMFFeedImage(image: $0, languageVariantCode: languageVariantCode) },
            newsStories: response.news?.map { WMFFeedNewsStory(newsItem: $0, languageVariantCode: languageVariantCode) }
        )
    }

    /// The key of the stored max age value.
    @objc(WMFFeedDayResponseMaxAgeKey)
    public static func maxAgeKey() -> String {
        return "WMFFeedDayResponseMaxAge"
    }
}
