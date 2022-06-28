import Foundation
import WMF

struct TalkPageAPIResponse: Codable {
    let threads: TalkPageThreadItems
    
    enum CodingKeys: String, CodingKey {
        case threads = "discussiontoolspageinfo"
    }
}

struct TalkPageThreadItems: Codable {
    let threadItems: [TalkPageItem]
    
    enum CodingKeys: String, CodingKey {
        case threadItems = "threaditemshtml"
    }
}

struct TalkPageItem: Codable {
    let type: TalkPageItemType
    let level: Int?
    let id: String?
    let html: String?
    let headingLevel: Int?
    let placeholderHeading: Bool?
    let replies: [TalkPageItem]
    let otherContent: String?

    
    enum CodingKeys: String, CodingKey {
        case type, level, id, html,headingLevel, placeholderHeading, replies
        case otherContent = "othercontent"
    }
    
    enum TalkPageItemType: String, Codable {
        case comment = "comment"
        case heading = "heading"
    }
}

class TalkPageFetcher: Fetcher {
    
    func fetchTalkPageContent(url: URL, completion: @escaping (_ result: Result<[TalkPageItem], Error>) -> Void) {
        guard let pageTitle = url.wmf_title else {
            completion(.failure(RequestError.invalidParameters))
            return
        }
        
        let params = ["action" : "discussiontoolspageinfo",
                      "page" : pageTitle,
                      "format": "json",
                      "prop" : "threaditemshtml",
                      "fomatversion" : "2"
        ]

        performDecodableMediaWikiAPIGET(for: url, with: params) { (result: Result<TalkPageAPIResponse, Error>) in
            switch result {
            case let .success(talk):
                completion(.success(talk.threads.threadItems))
                
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }

}
