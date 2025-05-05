import Foundation

public struct WMFArticleSummary: Decodable {
    public let displayTitle: String
    public let description: String?
    public let extractHtml: String
    public let thumbnailURL: URL?
    public let extract: String?
    
    enum CodingKeys: String, CodingKey {
        case displayTitle = "displaytitle"
        case description = "description"
        case extractHtml = "extract_html"
        case thumbnail = "thumbnail"
        case extract = "extract"
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        displayTitle = try container.decode(String.self, forKey: .displayTitle)
        description = try container.decodeIfPresent(String.self, forKey: .description)
        extractHtml = try container.decode(String.self, forKey: .extractHtml)
        extract = try container.decodeIfPresent(String.self, forKey: .extract)
        
        // Decode thumbnail URL from the thumbnail object
        if let thumbnailContainer = try? container.nestedContainer(keyedBy: ThumbnailCodingKeys.self, forKey: .thumbnail) {
            let source = try thumbnailContainer.decode(String.self, forKey: .source)
            thumbnailURL = URL(string: source)
        } else {
            thumbnailURL = nil
        }
    }
    
    private enum ThumbnailCodingKeys: String, CodingKey {
        case source
    }
    
    public init(displayTitle: String, description: String?, extractHtml: String, thumbnailURL: URL?, extract: String?) {
        self.displayTitle = displayTitle
        self.description = description
        self.extractHtml = extractHtml
        self.thumbnailURL = thumbnailURL
        self.extract = extract
    }
}
