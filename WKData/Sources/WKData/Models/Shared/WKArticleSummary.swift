import Foundation

struct WKArticleSummary: Decodable {
    let displayTitle: String
    let description: String
    let extractHtml: String
    
    enum CodingKeys: String, CodingKey {
        case displayTitle = "displaytitle"
        case description = "description"
        case extractHtml = "extract_html"
    }
}
