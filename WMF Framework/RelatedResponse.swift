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

struct Thumbnail: Codable {
    let source: String?
    let width: Int?
    let height: Int?
}

