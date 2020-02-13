public struct MediaListItemSource: Codable {
    public let urlString: String
    public let scale: String
    
    enum CodingKeys: String, CodingKey {
        case urlString = "src"
        case scale
    }
}

public enum MediaListItemType: String {
    case image
    case audio
    case video
}

public struct MediaListItem: Codable {
    public let title: String?
    public let sectionID: Int
    public let type: String
    public let showInGallery: Bool
    public let sources: [MediaListItemSource]?
    public let audioType: String?
    enum CodingKeys: String, CodingKey {
        case title
        case sectionID = "section_id"
        case showInGallery
        case sources = "srcset"
        case type
        case audioType
    }
}

extension MediaListItem {
    public var itemType: MediaListItemType? {
        return MediaListItemType(rawValue: type)
    }
}

public struct MediaList: Codable {
    public let items: [MediaListItem]
}
