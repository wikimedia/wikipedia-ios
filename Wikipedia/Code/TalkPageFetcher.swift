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
                      "formatversion" : "2"
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
    
    func postReply(talkPageTitle: String, siteURL: URL, commentId: String, comment: String, completion: @escaping(Result<Void, Error>) -> Void) {
        guard let title = talkPageTitle.denormalizedPageTitle else {
            completion(.failure(RequestError.invalidParameters))
            return
        }
        
        let params = ["action": "discussiontoolsedit",
                      "paction": "addcomment",
                      "page": title,
                      "format": "json",
                      "formatversion" : "2",
                      "commentid": commentId,
                      "wikitext": comment
                      
        ]
        
        performTokenizedMediaWikiAPIPOST(to: siteURL, with: params, reattemptLoginOn401Response: false) { result, httpResponse, error in
            
            self.evaluateResponse(error, result, completion: completion)
        }
    }
    
    
    func postTopic(talkPageTitle: String, siteURL: URL, topicTitle: String, topicBody: String, completion: @escaping(Result<Void, Error>) -> Void) {
        
        guard let title = talkPageTitle.denormalizedPageTitle else {
            completion(.failure(RequestError.invalidParameters))
            return
        }
        
        let params = ["action": "discussiontoolsedit",
                      "paction": "addtopic",
                      "page": title,
                      "format": "json",
                      "formatversion" : "2",
                      "sectiontitle": topicTitle,
                      "wikitext": topicBody        ]
        
        performTokenizedMediaWikiAPIPOST(to: siteURL, with: params, reattemptLoginOn401Response: false) { result, httpResponse, error in
            
            self.evaluateResponse(error, result, completion: completion)
        }
    }
    
    fileprivate func evaluateResponse(_ error: Error?, _ result: [String : Any]?, completion: @escaping(Result<Void, Error>) -> Void) {
        if let error = error {
            completion(.failure(error))
            return
        }
        
        if let resultError = result?["error"] as? [String: Any],
           let info = resultError["info"] as? String {
            completion(.failure(RequestError.api(info)))
            return
        }
        
        guard let discussionToolsEdit = result?["discussiontoolsedit"] as? [String: Any],
              let discussionToolsEditResult = discussionToolsEdit["result"] as? String,
              discussionToolsEditResult == "success" else {
            completion(.failure(RequestError.unexpectedResponse))
            return
        }
        
        completion(.success(()))
    }
    
}
