import Foundation

/// Represents the response structure of an article summary from the Page Content Service /page/summary endpoint
@objc(WMFArticleSummary)
public class ArticleSummary: NSObject, Codable {
    
    @objc public class Namespace: NSObject, Codable {
        
        let id: Int?
        let text: String?

        @objc public var number: NSNumber? {
            guard let id = id else {
                return nil
            }
            return NSNumber(value: id)
        }
        
        internal init(id: Int? = nil, text: String? = nil) {
            self.id = id
            self.text = text
        }
    }
    let id: Int64?
    let wikidataID: String?
    let revision: String?
    let timestamp: String?
    let index: Int?
    @objc let namespace: Namespace?
    let title: String?
    let displayTitle: String?
    let articleDescription: String?
    let extract: String?
    let extractHTML: String?
    let thumbnail: ArticleSummaryImage?
    let original: ArticleSummaryImage?
    @objc let coordinates: ArticleSummaryCoordinates?
    var languageVariantCode: String?
    
    enum CodingKeys: String, CodingKey {
        case id = "pageid"
        case revision
        case index
        case namespace
        case title
        case timestamp
        case displayTitle = "displaytitle"
        case articleDescription = "description"
        case extract
        case extractHTML = "extract_html"
        case thumbnail
        case original = "originalimage"
        case coordinates
        case contentURLs = "content_urls"
        case wikidataID = "wikibase_item"
    }
    
    let contentURLs: ArticleSummaryContentURLs
    
    var articleURL: URL? {
        guard let urlString = contentURLs.desktop?.page else {
            return nil
        }
        var articleURL = URL(string: urlString)
        articleURL?.wmf_languageVariantCode = languageVariantCode
        return articleURL
    }
    
    var key: WMFInMemoryURLKey? {
        return articleURL?.wmf_inMemoryKey // don't use contentURLs.desktop?.page directly as it needs to be standardized
    }
    
    internal init(id: Int64? = nil, wikidataID: String? = nil, revision: String? = nil, timestamp: String? = nil, index: Int? = nil, namespace: ArticleSummary.Namespace? = nil, title: String? = nil, displayTitle: String? = nil, articleDescription: String? = nil, extract: String? = nil, extractHTML: String? = nil, thumbnail: ArticleSummaryImage? = nil, original: ArticleSummaryImage? = nil, coordinates: ArticleSummaryCoordinates? = nil, languageVariantCode: String? = nil, contentURLs: ArticleSummaryContentURLs) {
        self.id = id
        self.wikidataID = wikidataID
        self.revision = revision
        self.timestamp = timestamp
        self.index = index
        self.namespace = namespace
        self.title = title
        self.displayTitle = displayTitle
        self.articleDescription = articleDescription
        self.extract = extract
        self.extractHTML = extractHTML
        self.thumbnail = thumbnail
        self.original = original
        self.coordinates = coordinates
        self.languageVariantCode = languageVariantCode
        self.contentURLs = contentURLs
    }
}

@objc(WMFArticleSummaryImage)
class ArticleSummaryImage: NSObject, Codable {
    
    let source: String
    let width: Int
    let height: Int
    var url: URL? {
        return URL(string: source)
    }
    
    internal init(source: String, width: Int, height: Int) {
        self.source = source
        self.width = width
        self.height = height
    }
}

@objc(WMFArticleSummaryURLs)
class ArticleSummaryURLs: NSObject, Codable {
    let page: String?
    let revisions: String?
    let edit: String?
    let talk: String?
    
    internal init(page: String? = nil, revisions: String? = nil, edit: String? = nil, talk: String? = nil) {
        self.page = page
        self.revisions = revisions
        self.edit = edit
        self.talk = talk
    }
}

@objc(WMFArticleSummaryContentURLs)
class ArticleSummaryContentURLs: NSObject, Codable {
    let desktop: ArticleSummaryURLs?
    let mobile: ArticleSummaryURLs?
    
    internal init(desktop: ArticleSummaryURLs? = nil, mobile: ArticleSummaryURLs? = nil) {
        self.desktop = desktop
        self.mobile = mobile
    }
}

@objc(WMFArticleSummaryCoordinates)
class ArticleSummaryCoordinates: NSObject, Codable {
    @objc let lat: Double
    @objc let lon: Double
}
