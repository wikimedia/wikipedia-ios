import Foundation

public struct WMFFeedAPIResponse: Codable, Sendable {
    public let todaysFeaturedArticle: WMFFeedArticle?
    public let mostRead: WMFFeedMostRead?
    public let image: WMFFeedImageNew?
    public let news: [WMFFeedNewsItem]?
    // onthisday intentionally omitted — see T418486

    enum CodingKeys: String, CodingKey {
        case todaysFeaturedArticle = "tfa"
        case mostRead = "mostread"
        case image
        case news
    }
}

// MARK: - Shared article type (used for TFA, most-read articles, and news links)

public struct WMFFeedArticle: Codable, Sendable {
    public let type: String?
    public let title: String?
    public let displayTitle: String?
    public let normalizedTitle: String?
    public let namespace: WMFFeedNamespace?
    public let wikibaseItem: String?
    public let titles: WMFFeedArticleTitles?
    public let pageid: Int?
    public let thumbnail: WMFFeedImageSource?
    public let originalImage: WMFFeedImageSource?
    public let lang: String?
    public let dir: String?
    public let revision: String?
    public let tid: String?
    public let timestamp: String?
    public let description: String?
    public let descriptionSource: String?
    public let contentURLs: WMFFeedContentURLs?
    public let extract: String?
    public let extractHTML: String?

    enum CodingKeys: String, CodingKey {
        case type, title, namespace, titles, pageid, thumbnail
        case originalImage = "originalimage"
        case lang, dir, revision, tid, timestamp, description
        case displayTitle = "displaytitle"
        case normalizedTitle = "normalizedtitle"
        case wikibaseItem = "wikibase_item"
        case descriptionSource = "description_source"
        case contentURLs = "content_urls"
        case extract
        case extractHTML = "extract_html"
    }
}

public struct WMFFeedArticleTitles: Codable, Sendable {
    public let canonical: String?
    public let normalized: String?
    public let display: String?
}

public struct WMFFeedNamespace: Codable, Sendable {
    public let id: Int?
    public let text: String?
}

// MARK: - Content URLs

public struct WMFFeedContentURLs: Codable, Sendable {
    public let desktop: WMFFeedContentURLGroup?
    public let mobile: WMFFeedContentURLGroup?
}

public struct WMFFeedContentURLGroup: Codable, Sendable {
    public let page: String?
    public let revisions: String?
    public let edit: String?
    public let talk: String?
}

// MARK: - Most Read

public struct WMFFeedMostRead: Codable, Sendable {
    public let date: String?
    public let articles: [WMFFeedMostReadArticle]?
}

public struct WMFFeedMostReadArticle: Codable, Sendable {
    public let views: Int?
    public let rank: Int?
    public let viewHistory: [WMFFeedViewHistoryEntry]?
    public let type: String?
    public let title: String?
    public let displayTitle: String?
    public let normalizedTitle: String?
    public let namespace: WMFFeedNamespace?
    public let wikibaseItem: String?
    public let titles: WMFFeedArticleTitles?
    public let pageid: Int?
    public let thumbnail: WMFFeedImageSource?
    public let originalimage: WMFFeedImageSource?
    public let lang: String?
    public let description: String?
    public let descriptionSource: String?
    public let extract: String?
    public let extractHTML: String?
    public let contentURLs: WMFFeedContentURLs?

    enum CodingKeys: String, CodingKey {
        case views, rank, type, title, namespace, titles, pageid, thumbnail, originalimage, lang, description, extract
        case viewHistory = "view_history"
        case displayTitle = "displaytitle"
        case normalizedTitle = "normalizedtitle"
        case wikibaseItem = "wikibase_item"
        case descriptionSource = "description_source"
        case extractHTML = "extract_html"
        case contentURLs = "content_urls"
    }
}

public struct WMFFeedViewHistoryEntry: Codable, Sendable {
    public let date: String?
    public let views: Int?
}

// MARK: - Image source (shared thumbnail/originalimage shape)

public struct WMFFeedImageSource: Codable, Sendable {
    public let source: String?
    public let width: Int?
    public let height: Int?
}

// MARK: - Image of the Day

public struct WMFFeedImageNew: Codable, Sendable {
    public let title: String?
    public let thumbnail: WMFFeedImageSource?
    public let image: WMFFeedImageSource?
    public let filePage: String?
    public let artist: WMFFeedImageArtist?
    public let credit: WMFFeedLocalizedValue?
    public let license: WMFFeedImageLicense?
    public let description: WMFFeedLocalizedValue?
    public let wbEntityId: String?
    public let structured: WMFFeedImageStructured?

    enum CodingKeys: String, CodingKey {
        case title, thumbnail, image, artist, credit, license, description, structured
        case filePage = "file_page"
        case wbEntityId = "wb_entity_id"
    }
}

public struct WMFFeedImageArtist: Codable, Sendable {
    public let html: String?
    public let text: String?
    public let name: String?
    public let userPage: String?

    enum CodingKeys: String, CodingKey {
        case html, text, name
        case userPage = "user_page"
    }
}

public struct WMFFeedLocalizedValue: Codable, Sendable {
    public let html: String?
    public let text: String?
    public let lang: String?
}

public struct WMFFeedImageLicense: Codable, Sendable {
    public let type: String?
    public let code: String?
    public let url: String?
}

public struct WMFFeedImageStructured: Codable, Sendable {
    public let captions: [String: String]?
}

// MARK: - News

public struct WMFFeedNewsItem: Codable, Sendable {
    public let story: String?
    public let links: [WMFFeedArticle]?
}
