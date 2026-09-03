import Foundation
import WMFData
import WMFNativeLocalizations

/// A news story for the Explore feed.
///
/// This class is a temporary bridge. WMFData decodes the story into a `WMFFeedNewsItem` struct.
/// The Explore feed archives this class into Core Data with NSSecureCoding. The class name and the
/// coding keys are the same as the old Mantle model, so archives from earlier app versions still decode.
/// Remove this class when the Explore feed is removed.
@objc(WMFFeedNewsStory)
@objcMembers
public final class WMFFeedNewsStory: NSObject, NSSecureCoding {

    public let storyHTML: String?
    public var featuredArticlePreview: WMFFeedArticlePreview?
    public let articlePreviews: [WMFFeedArticlePreview]?
    /// The month and day of the story at midnight UTC. The year of this date is not valid.
    public let midnightUTCMonthAndDay: Date?

    public init(storyHTML: String?, articlePreviews: [WMFFeedArticlePreview]?, featuredArticlePreview: WMFFeedArticlePreview?, midnightUTCMonthAndDay: Date?) {
        self.storyHTML = storyHTML
        self.articlePreviews = articlePreviews
        self.featuredArticlePreview = featuredArticlePreview
        self.midnightUTCMonthAndDay = midnightUTCMonthAndDay
        super.init()
    }

    /// Create the bridge object from the WMFData model.
    public convenience init(newsItem: WMFFeedNewsItem, languageVariantCode: String?) {
        let previews = (newsItem.links ?? []).compactMap { WMFFeedArticlePreview(article: $0, languageVariantCode: languageVariantCode) }
        self.init(storyHTML: newsItem.story, articlePreviews: previews, featuredArticlePreview: nil, midnightUTCMonthAndDay: newsItem.storyMonthAndDay)
    }

    /// The title of the article that the story marks as pictured.
    @objc(semanticFeaturedArticleTitleFromStoryHTML:siteURL:)
    public static func semanticFeaturedArticleTitle(fromStoryHTML storyHTML: String, siteURL: URL) -> String? {
        let pictured = localizedPicturedText(forWikiLanguage: siteURL.wmf_languageCode)
        return WMFFeedNewsItem.picturedArticleTitle(fromStoryHTML: storyHTML, picturedText: pictured)
    }

    /// The word "pictured" in the language of the wiki.
    public static func localizedPicturedText(forWikiLanguage languageCode: String?) -> String {
        return WMFLocalizedString("pictured", languageCode: languageCode, value: "pictured", comment: "Indicates the person or item is pictured (as in a news story).")
    }

    // MARK: - Language variant

    /// Set the language variant code on the article previews. The content group calls this method after it decodes the object.
    public func propagateLanguageVariantCode(_ languageVariantCode: String?) {
        featuredArticlePreview?.propagateLanguageVariantCode(languageVariantCode)
        articlePreviews?.forEach { $0.propagateLanguageVariantCode(languageVariantCode) }
    }

    // MARK: - NSSecureCoding

    public static var supportsSecureCoding: Bool { true }

    private enum Key {
        static let storyHTML = "storyHTML"
        static let featuredArticlePreview = "featuredArticlePreview"
        static let articlePreviews = "articlePreviews"
        static let midnightUTCMonthAndDay = "midnightUTCMonthAndDay"
    }

    public init?(coder: NSCoder) {
        storyHTML = coder.decodeObject(of: NSString.self, forKey: Key.storyHTML) as String?
        featuredArticlePreview = coder.decodeObject(of: WMFFeedArticlePreview.self, forKey: Key.featuredArticlePreview)
        articlePreviews = coder.decodeObject(of: [NSArray.self, WMFFeedArticlePreview.self], forKey: Key.articlePreviews) as? [WMFFeedArticlePreview]
        midnightUTCMonthAndDay = coder.decodeObject(of: NSDate.self, forKey: Key.midnightUTCMonthAndDay) as Date?
        super.init()
    }

    public func encode(with coder: NSCoder) {
        coder.encode(storyHTML, forKey: Key.storyHTML)
        coder.encode(featuredArticlePreview, forKey: Key.featuredArticlePreview)
        coder.encode(articlePreviews, forKey: Key.articlePreviews)
        coder.encode(midnightUTCMonthAndDay, forKey: Key.midnightUTCMonthAndDay)
    }

    // MARK: - Equality

    public override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? WMFFeedNewsStory else {
            return false
        }
        return storyHTML == other.storyHTML
            && midnightUTCMonthAndDay == other.midnightUTCMonthAndDay
            && (articlePreviews ?? []) == (other.articlePreviews ?? [])
    }

    public override var hash: Int {
        var hasher = Hasher()
        hasher.combine(storyHTML)
        return hasher.finalize()
    }
}
