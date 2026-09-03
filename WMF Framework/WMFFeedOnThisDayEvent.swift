import Foundation
import WMFData

/// An on-this-day event for the Explore feed and the On This Day widget.
///
/// This class is a temporary bridge. WMFData decodes the event into a `WMFOnThisDayEvent` struct.
/// The Explore feed archives this class into Core Data with NSSecureCoding. The class name and the
/// coding keys are the same as the old Mantle model, so archives from earlier app versions still decode.
/// Remove this class when the Explore feed is removed.
@objc(WMFFeedOnThisDayEvent)
@objcMembers
public final class WMFFeedOnThisDayEvent: NSObject, NSSecureCoding {

    public let text: String?
    public let year: NSNumber?
    public let articlePreviews: [WMFFeedArticlePreview]?
    /// The rank score. The content source sets it before it saves the events.
    public var score: NSNumber?
    /// The position in the list of events. The content source sets it before it saves the events.
    public var index: NSNumber?

    /// The site of the first article preview.
    public var siteURL: URL? {
        return articlePreviews?.first?.articleURL.wmf_site
    }

    public var languageCode: String? {
        return siteURL?.wmf_languageCode
    }

    public var contentLanguageCode: String? {
        return siteURL?.wmf_contentLanguageCode
    }

    public init(text: String?, year: NSNumber?, articlePreviews: [WMFFeedArticlePreview]?) {
        self.text = text
        self.year = year
        self.articlePreviews = articlePreviews
        super.init()
    }

    /// Create the bridge object from the WMFData model.
    public convenience init(event: WMFOnThisDayEvent, languageVariantCode: String?) {
        let previews = event.pages.compactMap { WMFFeedArticlePreview(page: $0, languageVariantCode: languageVariantCode) }
        self.init(text: event.text, year: NSNumber(value: event.year), articlePreviews: previews)
    }

    /// Compute the rank score of the event.
    public func calculateScore() -> NSNumber {
        let imageCount = (articlePreviews ?? []).filter { $0.imageURLString != nil }.count
        return NSNumber(value: WMFOnThisDayEvent.score(text: text, imageCount: imageCount, languageCode: languageCode))
    }

    // MARK: - Language variant

    /// Set the language variant code on the article previews. The content group calls this method after it decodes the object.
    public func propagateLanguageVariantCode(_ languageVariantCode: String?) {
        articlePreviews?.forEach { $0.propagateLanguageVariantCode(languageVariantCode) }
    }

    // MARK: - NSSecureCoding

    public static var supportsSecureCoding: Bool { true }

    private enum Key {
        static let text = "text"
        static let year = "year"
        static let articlePreviews = "articlePreviews"
        static let score = "score"
        static let index = "index"
    }

    public init?(coder: NSCoder) {
        text = coder.decodeObject(of: NSString.self, forKey: Key.text) as String?
        year = coder.decodeObject(of: NSNumber.self, forKey: Key.year)
        articlePreviews = coder.decodeObject(of: [NSArray.self, WMFFeedArticlePreview.self], forKey: Key.articlePreviews) as? [WMFFeedArticlePreview]
        score = coder.decodeObject(of: NSNumber.self, forKey: Key.score)
        index = coder.decodeObject(of: NSNumber.self, forKey: Key.index)
        super.init()
    }

    public func encode(with coder: NSCoder) {
        coder.encode(text, forKey: Key.text)
        coder.encode(year, forKey: Key.year)
        coder.encode(articlePreviews, forKey: Key.articlePreviews)
        coder.encode(score, forKey: Key.score)
        coder.encode(index, forKey: Key.index)
    }

    // MARK: - Equality

    public override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? WMFFeedOnThisDayEvent else {
            return false
        }
        return text == other.text
            && year == other.year
            && (articlePreviews ?? []) == (other.articlePreviews ?? [])
    }

    public override var hash: Int {
        var hasher = Hasher()
        hasher.combine(text)
        hasher.combine(year)
        return hasher.finalize()
    }
}
