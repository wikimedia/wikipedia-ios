import Foundation
import WMF

class TalkPageResponse: Codable {
    let pageinfo: [TalkPageThreadItems]
    
    enum CodingKeys: String, CodingKey {
        case pageinfo = "discussiontoolspageinfo"
    }
}

class TalkPageThreadItems: Codable {
    let threadItemsHTML: [TalkPageItem]
    
    enum CodingKeys: String, CodingKey {
        case threadItemsHTML = "threaditemshtml"
    }
}

class TalkPageItem: Codable {
    let type: String
    let level: Int
    let id: String
    let html: String
    let headingLevel: Int
    let placeholderHeading: Bool
    let replies: [TalkPageItem]
}

class TalkPageFetcher: Fetcher {
    
}
