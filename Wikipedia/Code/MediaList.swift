public struct MediaListItemSource: Codable {
    public let urlString: String
    public let scale: String
    
    enum CodingKeys: String, CodingKey {
        case urlString = "src"
        case scale
    }

    public init (urlString: String, scale: String) {
        self.urlString = urlString
        self.scale = scale
    }
}

public enum MediaListItemType: String, Codable {
    case image
    case audio
    case video
}

public struct MediaListItem: Codable {
    public let title: String?
    public let sectionID: Int
    public let type: MediaListItemType
    public let showInGallery: Bool
    public let isLeadImage: Bool
    public let sources: [MediaListItemSource]?
    public let audioType: String?
    enum CodingKeys: String, CodingKey {
        case title
        case sectionID = "section_id"
        case showInGallery
        case isLeadImage = "leadImage"
        case sources = "srcset"
        case type
        case audioType
    }

    public init(title: String?, sectionID: Int, type: MediaListItemType, showInGallery: Bool, isLeadImage: Bool, sources: [MediaListItemSource]?, audioType: String? = nil) {
        self.title = title
        self.sectionID = sectionID
        self.type = type
        self.showInGallery = showInGallery
        self.isLeadImage = isLeadImage
        self.sources = sources
        self.audioType = audioType
    }
}


public struct MediaList: Codable {
    public let items: [MediaListItem]

    public init(items: [MediaListItem]) {
        self.items = items
    }

    // This failable initializer is used for a single-image MediaList, given via a URL.
    public init?(from url: URL?) {
        guard let imageURL = url,
            let imageName = WMFParseUnescapedNormalizedImageNameFromSourceURL(imageURL) else {
            return nil
        }
        let filename = "File:" + imageName
        let urlString = imageURL.absoluteString
        let sources: [MediaListItemSource] = [
            MediaListItemSource(urlString: urlString, scale: "1x"),
            MediaListItemSource(urlString: urlString, scale: "2x"),
            MediaListItemSource(urlString: urlString, scale: "1.5x")
        ]

        let mediaListItem = MediaListItem(title: filename, sectionID: 0, type: .image, showInGallery: true, isLeadImage: true, sources: sources, audioType: nil)
        self = MediaList(items: [mediaListItem])
    }
}
