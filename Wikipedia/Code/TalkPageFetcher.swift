import Foundation
import WMF

struct TalkPageResponse: Codable {
    let pageInfo: TalkPageThreadItems?
    
    enum CodingKeys: String, CodingKey {
        case pageInfo = "discussiontoolspageinfo"
    }
}

struct TalkPageThreadItems: Codable {
    let threadItemsHTML: [TalkPageItem]?
    
    enum CodingKeys: String, CodingKey {
        case threadItemsHTML = "threaditemshtml"
    }
}

struct TalkPageItem: Codable {
    let type: String?
    let level: Int?
    let id: String?
    let html: String?
    let headingLevel: Int?
    let placeholderHeading: Bool?
    let replies: [TalkPageItem]?
}

class TalkPageFetcher: Fetcher {
    
    func fetchTalkPageContent() {
       guard let thisURL = URL(string:
                                "https://en.wikipedia.org/w/api.php?action=discussiontoolspageinfo&format=json&page=User_talk:Tsevener&prop=threaditemshtml&formatversion=2") else {
           return
       }
        
        session.jsonDecodableTask(with: thisURL) { (result: TalkPageResponse?, response: URLResponse?, error: Error? ) in
            print("RESULT \(result), ERROR \(error)")
        }
    }
}
