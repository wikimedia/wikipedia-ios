import Foundation

public struct WMFArticleSummary: Decodable {
    public let displayTitle: String
    public let description: String?
    public let extractHtml: String
    
    enum CodingKeys: String, CodingKey {
        case displayTitle = "displaytitle"
        case description = "description"
        case extractHtml = "extract_html"
    }
}
