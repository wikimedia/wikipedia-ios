import Foundation

struct RelatedResponse: Codable {
    let batchcomplete: Bool
    let continueInfo: ContinueInfo?
    let query: Query?

    enum CodingKeys: String, CodingKey {
        case batchcomplete
        case continueInfo = "continue"
        case query
    }
}

struct ContinueInfo: Codable {
    let gsroffset: Int
    let continueValue: String

    enum CodingKeys: String, CodingKey {
        case gsroffset
        case continueValue = "continue"
    }
}

struct Query: Codable {
    let pages: [Page]
}

struct Page: Codable {
    let pageid: Int
    let ns: Int
    let title: String
    let index: Int
    let thumbnail: Thumbnail?
    let description: String?
    let descriptionsource: String?
    let contentmodel: String
    let pagelanguage: String
    let pagelanguagehtmlcode: String
    let pagelanguagedir: String
    let touched: String
    let lastrevid: Int
    let length: Int
    let varianttitles: [String: String]?

}

public struct Thumbnail: Codable {
    let source: String?
    let width: Int?
    let height: Int?
}


@objc(WMFRelatedPage)
public class RelatedPage: NSObject {
    public let pageId: Int
    public let ns: Int
    public let title: String
    public let index: Int
    public let thumbnail: Thumbnail?
    public let articleDescription: String?
    public let descriptionSource: String?
    public let contentModel: String
    public let pageLanguage: String
    public let pageLanguageHtmlCode: String
    public let pageLanguageDir: String
    public let touched: String
    public let lastRevId: Int
    public let length: Int

    var languageVariantCode: String?

    var articleURL: URL?

    var key: WMFInMemoryURLKey? {
        articleURL?.wmf_languageVariantCode = languageVariantCode
        return articleURL?.wmf_inMemoryKey
    }

    public init(pageId: Int, ns: Int, title: String, index: Int, thumbnail: Thumbnail?, articleDescription: String?, descriptionSource: String?, contentModel: String, pageLanguage: String, pageLanguageHtmlCode: String, pageLanguageDir: String, touched: String, lastRevId: Int, length: Int) {
        self.pageId = pageId
        self.ns = ns
        self.title = title
        self.index = index
        self.thumbnail = thumbnail
        self.articleDescription = articleDescription
        self.descriptionSource = descriptionSource
        self.contentModel = contentModel
        self.pageLanguage = pageLanguage
        self.pageLanguageHtmlCode = pageLanguageHtmlCode
        self.pageLanguageDir = pageLanguageDir
        self.touched = touched
        self.lastRevId = lastRevId
        self.length = length
    }
}
