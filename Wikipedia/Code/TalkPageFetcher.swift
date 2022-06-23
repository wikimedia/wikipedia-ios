import Foundation
import WMF

struct TalkPageAPIResponse: Codable {
    let threads: TalkPageThreadItems?
    
    enum CodingKeys: String, CodingKey {
        case threads = "discussiontoolspageinfo"
    }
}

struct TalkPageThreadItems: Codable {
    let threadItems: [TalkPageItem]?
    
    enum CodingKeys: String, CodingKey {
        case threadItems = "threaditemshtml"
    }
    
    init(items: [TalkPageItem]) {
        self.threadItems = items
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
    
    func fetchTalkPageContent(url: URL, completion: @escaping (Result<TalkPageAPIResponse?, Error>) -> Void) {
        guard let pageTitle = url.wmf_title else {
            return
        }
        
        let params = ["action" : "discussiontoolspageinfo",
                      "page" : pageTitle,
                      "format": "json",
                      "prop" : "threaditemshtml",
                      "fomatversion" : "2"
        ]

        performDecodableMediaWikiAPIGET(for: url, with: params) { (result: Result<TalkPageAPIResponse?, Error>) in
            switch result {
            case let .success(talk):
                completion(.success(talk))
                
            case .failure:
                completion(.failure(RequestError.invalidParameters))
            }
        }
    }

}
