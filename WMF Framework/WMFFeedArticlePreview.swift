import Foundation
import WMFData

/// An article preview for the Explore feed.
///
/// This class is a temporary bridge. WMFData decodes the feed into `WMFFeedArticle`, `WMFFeedMostReadArticle`
/// and `WMFOnThisDayPage` structs. The Explore feed archives this class into Core Data with NSSecureCoding.
/// The class name and the coding keys are the same as the old Mantle model, so archives from earlier app
/// versions still decode. Remove this class when the Explore feed is removed.
@objc(WMFFeedArticlePreview)
@objcMembers
public class WMFFeedArticlePreview: NSObject, NSSecureCoding {

    public let displayTitle: String
    private let storedDisplayTitleHTML: String?
    public var wikidataDescription: String?
    public var snippet: String?
    public var thumbnailURL: URL?
    public var imageURLString: String?
    public var imageWidth: NSNumber?
    public var imageHeight: NSNumber?
    public var articleURL: URL

    /// The display title with HTML. Falls back to the plain display title when the HTML title is empty.
    public var displayTitleHTML: String {
        if let storedDisplayTitleHTML, !storedDisplayTitleHTML.isEmpty {
            return storedDisplayTitleHTML
        }
        return displayTitle
    }

    public init(articleURL: URL, displayTitle: String, displayTitleHTML: String?, wikidataDescription: String?, snippet: String?, thumbnailURL: URL?, imageURLString: String?, imageWidth: NSNumber?, imageHeight: NSNumber?) {
        self.articleURL = articleURL
        self.displayTitle = displayTitle
        self.storedDisplayTitleHTML = displayTitleHTML
        self.wikidataDescription = wikidataDescription
        self.snippet = snippet
        self.thumbnailURL = thumbnailURL
        self.imageURLString = imageURLString
        self.imageWidth = imageWidth
        self.imageHeight = imageHeight
        super.init()
    }

    /// Create the bridge object from the common fields of the WMFData feed models.
    /// The initializer fails when the model has no title or no article URL.
    init?(fields: WMFFeedArticleFields, languageVariantCode: String?) {
        guard let displayTitle = fields.normalizedTitle ?? fields.articleTitle,
              let articleURL = WMFFeedArticlePreview.articleURL(pageURLString: fields.pageURLString, languageCode: fields.languageCode, normalizedTitle: displayTitle) else {
            return nil
        }
        self.articleURL = articleURL
        self.displayTitle = displayTitle
        storedDisplayTitleHTML = fields.displayTitleHTML ?? displayTitle
        wikidataDescription = fields.description
        snippet = fields.extract.map { ($0 as NSString).wmf_summaryFromText() }
        thumbnailURL = fields.thumbnailURLString.flatMap { URL(string: $0) }
        imageURLString = fields.originalImageURLString
        imageWidth = fields.originalImageWidth.map { NSNumber(value: $0) }
        imageHeight = fields.originalImageHeight.map { NSNumber(value: $0) }
        super.init()
        propagateLanguageVariantCode(languageVariantCode)
    }

    public convenience init?(article: WMFFeedArticle, languageVariantCode: String?) {
        self.init(fields: article, languageVariantCode: languageVariantCode)
    }

    public convenience init?(page: WMFOnThisDayPage, languageVariantCode: String?) {
        self.init(fields: page, languageVariantCode: languageVariantCode)
    }

    /// Build the article URL from the desktop page URL.
    ///
    /// The page URL can fail to parse when it contains characters that are not escaped. In that case the
    /// URL comes from the language code and the normalized title. The language code from the host of the
    /// page URL is preferred, because the `lang` field uses codes like `yue` where the URL uses `zh-yue`.
    static func articleURL(pageURLString: String?, languageCode: String?, normalizedTitle: String) -> URL? {
        if let pageURLString, let url = URL(string: pageURLString) {
            return url
        }
        var language = languageCode
        if let pageURLString, let hostLanguage = WMFFeedArticlePreview.languageCode(fromURLString: pageURLString) {
            language = hostLanguage
        }
        guard let siteURL = NSURL.wmf_URL(withDefaultSiteAndLanguageCode: language) else {
            return nil
        }
        return siteURL.wmf_URL(withTitle: normalizedTitle)
    }

    private static let languageFromURLRegex = try? NSRegularExpression(pattern: "\\/\\/([^.]*)", options: [])

    static func languageCode(fromURLString urlString: String) -> String? {
        guard let regex = languageFromURLRegex,
              let match = regex.firstMatch(in: urlString, options: [], range: NSRange(urlString.startIndex..., in: urlString)),
              let range = Range(match.range(at: 1), in: urlString) else {
            return nil
        }
        return String(urlString[range])
    }

    // MARK: - Language variant

    /// Set the language variant code on the URL properties. The content group calls this method after it decodes the object.
    public func propagateLanguageVariantCode(_ languageVariantCode: String?) {
        thumbnailURL?.wmf_languageVariantCode = languageVariantCode
        articleURL.wmf_languageVariantCode = languageVariantCode
    }

    // MARK: - NSSecureCoding

    public class var supportsSecureCoding: Bool { true }

    private enum Key {
        static let displayTitleHTML = "displayTitleHTML"
        static let displayTitle = "displayTitle"
        static let wikidataDescription = "wikidataDescription"
        static let snippet = "snippet"
        static let thumbnailURL = "thumbnailURL"
        static let imageURLString = "imageURLString"
        static let imageWidth = "imageWidth"
        static let imageHeight = "imageHeight"
        static let articleURL = "articleURL"
    }

    public required init?(coder: NSCoder) {
        guard let articleURL = coder.decodeObject(of: NSURL.self, forKey: Key.articleURL) as URL? else {
            return nil
        }
        self.articleURL = articleURL
        displayTitle = (coder.decodeObject(of: NSString.self, forKey: Key.displayTitle) as String?) ?? ""
        storedDisplayTitleHTML = coder.decodeObject(of: NSString.self, forKey: Key.displayTitleHTML) as String?
        wikidataDescription = coder.decodeObject(of: NSString.self, forKey: Key.wikidataDescription) as String?
        snippet = coder.decodeObject(of: NSString.self, forKey: Key.snippet) as String?
        thumbnailURL = coder.decodeObject(of: NSURL.self, forKey: Key.thumbnailURL) as URL?
        imageURLString = coder.decodeObject(of: NSString.self, forKey: Key.imageURLString) as String?
        imageWidth = coder.decodeObject(of: NSNumber.self, forKey: Key.imageWidth)
        imageHeight = coder.decodeObject(of: NSNumber.self, forKey: Key.imageHeight)
        super.init()
    }

    public func encode(with coder: NSCoder) {
        coder.encode(articleURL, forKey: Key.articleURL)
        coder.encode(displayTitle, forKey: Key.displayTitle)
        coder.encode(storedDisplayTitleHTML, forKey: Key.displayTitleHTML)
        coder.encode(wikidataDescription, forKey: Key.wikidataDescription)
        coder.encode(snippet, forKey: Key.snippet)
        coder.encode(thumbnailURL, forKey: Key.thumbnailURL)
        coder.encode(imageURLString, forKey: Key.imageURLString)
        coder.encode(imageWidth, forKey: Key.imageWidth)
        coder.encode(imageHeight, forKey: Key.imageHeight)
    }

    // MARK: - Equality

    public override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? WMFFeedArticlePreview else {
            return false
        }
        return articleURL == other.articleURL
            && displayTitle == other.displayTitle
            && displayTitleHTML == other.displayTitleHTML
            && wikidataDescription == other.wikidataDescription
            && snippet == other.snippet
            && thumbnailURL == other.thumbnailURL
            && imageURLString == other.imageURLString
            && imageWidth == other.imageWidth
            && imageHeight == other.imageHeight
    }

    public override var hash: Int {
        var hasher = Hasher()
        hasher.combine(articleURL)
        hasher.combine(displayTitle)
        return hasher.finalize()
    }
}

/// A most-read article preview with the view count and the rank.
@objc(WMFFeedTopReadArticlePreview)
@objcMembers
public final class WMFFeedTopReadArticlePreview: WMFFeedArticlePreview {

    public var numberOfViews: NSNumber
    public var rank: NSNumber

    public init?(mostReadArticle: WMFFeedMostReadArticle, languageVariantCode: String?) {
        numberOfViews = NSNumber(value: mostReadArticle.views ?? 0)
        rank = NSNumber(value: mostReadArticle.rank ?? 0)
        super.init(fields: mostReadArticle, languageVariantCode: languageVariantCode)
    }

    private enum Key {
        static let numberOfViews = "numberOfViews"
        static let rank = "rank"
    }

    public override class var supportsSecureCoding: Bool { true }

    public required init?(coder: NSCoder) {
        numberOfViews = coder.decodeObject(of: NSNumber.self, forKey: Key.numberOfViews) ?? 0
        rank = coder.decodeObject(of: NSNumber.self, forKey: Key.rank) ?? 0
        super.init(coder: coder)
    }

    public override func encode(with coder: NSCoder) {
        super.encode(with: coder)
        coder.encode(numberOfViews, forKey: Key.numberOfViews)
        coder.encode(rank, forKey: Key.rank)
    }

    public override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? WMFFeedTopReadArticlePreview else {
            return false
        }
        return super.isEqual(other) && numberOfViews == other.numberOfViews && rank == other.rank
    }
}

// MARK: - Common fields of the WMFData feed models

/// The fields that the feed models share. The bridge reads them through this protocol.
protocol WMFFeedArticleFields {
    var articleTitle: String? { get }
    var normalizedTitle: String? { get }
    var displayTitleHTML: String? { get }
    var languageCode: String? { get }
    var description: String? { get }
    var extract: String? { get }
    var thumbnailURLString: String? { get }
    var originalImageURLString: String? { get }
    var originalImageWidth: Int? { get }
    var originalImageHeight: Int? { get }
    var pageURLString: String? { get }
}

extension WMFFeedArticle: WMFFeedArticleFields {
    var articleTitle: String? { title }
    var displayTitleHTML: String? { displayTitle }
    var languageCode: String? { lang }
    var thumbnailURLString: String? { thumbnail?.source }
    var originalImageURLString: String? { originalImage?.source }
    var originalImageWidth: Int? { originalImage?.width }
    var originalImageHeight: Int? { originalImage?.height }
    var pageURLString: String? { contentURLs?.desktop?.page }
}

extension WMFFeedMostReadArticle: WMFFeedArticleFields {
    var articleTitle: String? { title }
    var displayTitleHTML: String? { displayTitle }
    var languageCode: String? { lang }
    var thumbnailURLString: String? { thumbnail?.source }
    var originalImageURLString: String? { originalimage?.source }
    var originalImageWidth: Int? { originalimage?.width }
    var originalImageHeight: Int? { originalimage?.height }
    var pageURLString: String? { contentURLs?.desktop?.page }
}

extension WMFOnThisDayPage: WMFFeedArticleFields {
    var articleTitle: String? { title }
    var displayTitleHTML: String? { displayTitle }
    var languageCode: String? { lang }
    var thumbnailURLString: String? { thumbnail?.source.absoluteString }
    var originalImageURLString: String? { originalImage?.source.absoluteString }
    var originalImageWidth: Int? { originalImage?.width }
    var originalImageHeight: Int? { originalImage?.height }
    var pageURLString: String? { contentUrls?.desktop?.page?.absoluteString }
}
