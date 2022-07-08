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
    let id: String
    let html: String?
    let name: String?
    let headingLevel: Int?
    let replies: [TalkPageItem]
    let otherContent: String?

    
    enum CodingKeys: String, CodingKey {
        case type, level, id, html, name ,headingLevel, replies
        case otherContent = "othercontent"
    }
    
    enum TalkPageItemType: String, Codable {
        case comment = "comment"
        case heading = "heading"
    }
}

class TalkPageFetcher: Fetcher {
    
    func fetchTalkPageContent(talkPageTitle: String, siteURL: URL, completion: @escaping (Result<[TalkPageItem], Error>) -> Void) {
        guard let title = talkPageTitle.denormalizedPageTitle else {
            completion(.failure(RequestError.invalidParameters))
            return
        }
        
        let params = ["action" : "discussiontoolspageinfo",
                      "page" : title,
                      "format": "json",
                      "prop" : "threaditemshtml",
                      "fomatversion" : "2"
        ]

        performDecodableMediaWikiAPIGET(for: siteURL, with: params) { (result: Result<TalkPageAPIResponse, Error>) in
            switch result {
            case let .success(talk):
                completion(.success(talk.threads.threadItems))
                
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }
    
    func subscribeToTopic(talkPageTitle: String, siteURL: URL, topic: String, completion: @escaping (Result<Bool, Error>) -> Void) {
        
        guard let title = talkPageTitle.denormalizedPageTitle else {
            completion(.failure(RequestError.invalidParameters))
            return
        }
        
        let params = ["actions": "discussiontoolssubscribe",
                      "page": title,
                      "format": "json",
                      "commentname": topic,
                      "subscribe": "1",
                      "formatversion": "2"
        ]
        
        performTokenizedMediaWikiAPIPOST(to: siteURL, with: params, reattemptLoginOn401Response: true) { result, hhtpResponse, error in
            if let error = error {
                completion(.failure(error))
            }
            
            if let resultError = result?["error"] as? [String: Any],
                let info = resultError["info"] as? String {
                    completion(.failure(RequestError.api(info)))
            }
            
            if let resultSuccess = result?["subscribe"] as? Bool {
                if resultSuccess {
                    completion(.success(true))
                }
            }
        }
    }

}
