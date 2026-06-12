import Foundation

public struct WMFFeedAPIResponse: Codable {
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

public struct WMFFeedArticle: Codable {
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
        case type, title, namespace, titles, pageid, thumbnail, originalimage
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

public struct WMFFeedArticleTitles: Codable {
    public let canonical: String?
    public let normalized: String?
    public let display: String?
}

public struct WMFFeedNamespace: Codable {
    public let id: Int?
    public let text: String?
}

// MARK: - Content URLs

public struct WMFFeedContentURLs: Codable {
    public let desktopPage: String?
    public let desktopRevisions: String?
    public let desktopEdit: String?
    public let desktopTalk: String?
    public let mobilePage: String?
    public let mobileRevisions: String?
    public let mobileEdit: String?
    public let mobileTalk: String?

    private enum TopLevelKeys: String, CodingKey {
        case desktop, mobile
    }
    private enum PageKeys: String, CodingKey {
        case page, revisions, edit, talk
    }

    public init(from decoder: Decoder) throws {
        let top = try decoder.container(keyedBy: TopLevelKeys.self)

        if top.contains(.desktop) {
            let desktop = try top.nestedContainer(keyedBy: PageKeys.self, forKey: .desktop)
            desktopPage = try desktop.decodeIfPresent(String.self, forKey: .page)
            desktopRevisions = try desktop.decodeIfPresent(String.self, forKey: .revisions)
            desktopEdit = try desktop.decodeIfPresent(String.self, forKey: .edit)
            desktopTalk = try desktop.decodeIfPresent(String.self, forKey: .talk)
        } else {
            desktopPage = nil; desktopRevisions = nil; desktopEdit = nil; desktopTalk = nil
        }

        if top.contains(.mobile) {
            let mobile = try top.nestedContainer(keyedBy: PageKeys.self, forKey: .mobile)
            mobilePage = try mobile.decodeIfPresent(String.self, forKey: .page)
            mobileRevisions = try mobile.decodeIfPresent(String.self, forKey: .revisions)
            mobileEdit = try mobile.decodeIfPresent(String.self, forKey: .edit)
            mobileTalk = try mobile.decodeIfPresent(String.self, forKey: .talk)
        } else {
            mobilePage = nil; mobileRevisions = nil; mobileEdit = nil; mobileTalk = nil
        }
    }

    public func encode(to encoder: Encoder) throws {
        var top = encoder.container(keyedBy: TopLevelKeys.self)
        var desktop = top.nestedContainer(keyedBy: PageKeys.self, forKey: .desktop)
        try desktop.encodeIfPresent(desktopPage, forKey: .page)
        try desktop.encodeIfPresent(desktopRevisions, forKey: .revisions)
        try desktop.encodeIfPresent(desktopEdit, forKey: .edit)
        try desktop.encodeIfPresent(desktopTalk, forKey: .talk)
        var mobile = top.nestedContainer(keyedBy: PageKeys.self, forKey: .mobile)
        try mobile.encodeIfPresent(mobilePage, forKey: .page)
        try mobile.encodeIfPresent(mobileRevisions, forKey: .revisions)
        try mobile.encodeIfPresent(mobileEdit, forKey: .edit)
        try mobile.encodeIfPresent(mobileTalk, forKey: .talk)
    }
}

// MARK: - Most Read

public struct WMFFeedMostRead: Codable {
    public let date: String?
    public let articles: [WMFFeedMostReadArticle]?
}

public struct WMFFeedMostReadArticle: Codable {
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

public struct WMFFeedViewHistoryEntry: Codable {
    public let date: String?
    public let views: Int?
}

// MARK: - Image source (shared thumbnail/originalimage shape)

public struct WMFFeedImageSource: Codable {
    public let source: String?
    public let width: Int?
    public let height: Int?
}

// MARK: - Image of the Day

public struct WMFFeedImageNew: Codable {
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

public struct WMFFeedImageArtist: Codable {
    public let html: String?
    public let text: String?
    public let name: String?
    public let userPage: String?

    enum CodingKeys: String, CodingKey {
        case html, text, name
        case userPage = "user_page"
    }
}

public struct WMFFeedLocalizedValue: Codable {
    public let html: String?
    public let text: String?
    public let lang: String?
}

public struct WMFFeedImageLicense: Codable {
    public let type: String?
    public let code: String?
    public let url: String?
}

public struct WMFFeedImageStructured: Codable {
    public let captions: [String: String]?
}

// MARK: - News

public struct WMFFeedNewsItem: Codable {
    public let story: String?
    public let links: [WMFFeedArticle]?
}
