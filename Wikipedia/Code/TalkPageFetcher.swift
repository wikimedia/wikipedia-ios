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
    
    func subscribeToTopic(talkPageTitle: String, siteURL: URL, topic: String, shouldSubscribe: Bool, completion: @escaping (Result<Bool, Error>) -> Void) {
        
        guard let title = talkPageTitle.denormalizedPageTitle else {
            completion(.failure(RequestError.invalidParameters))
            return
        }
                
        var params = ["action": "discussiontoolssubscribe",
                      "page": title,
                      "format": "json",
                      "commentname": topic,
                      "formatversion": "2"
        ]
        
        if shouldSubscribe {
            params["subscribe"] = "1"
        }
        
        performTokenizedMediaWikiAPIPOST(to: siteURL, with: params, reattemptLoginOn401Response: true) { result, httpResponse, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            if let resultError = result?["error"] as? [String: Any],
               let info = resultError["info"] as? String {
                completion(.failure(RequestError.api(info)))
                return
            }
            
            if let resultSuccess = result?["discussiontoolssubscribe"] as? [String: Any],
                let didSubscribe = resultSuccess["subscribe"] as? Bool {
                completion(.success(didSubscribe))
                return
            }
            completion(.failure(RequestError.unexpectedResponse))
        }
    }
    
    func getAllSubscriptions(siteURL: URL, topics: [String], completion: @escaping (Result<[String], Error>) -> Void) {
        
        let joinedString = topics.joined(separator: "|")
        
        let params = ["action": "discussiontoolsgetsubscriptions",
                       "format": "json",
                       "commentname": joinedString,
                       "formatversion": "2"
        ]
        
        performMediaWikiAPIGET(for: siteURL, with: params, cancellationKey: nil) { result, httpResponse, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            if let resultError = result?["error"] as? [String: Any],
               let info = resultError["info"] as? String {
                completion(.failure(RequestError.api(info)))
                return
            }
            
            if let resultSuccess = result?["subscriptions"] as? [String: Any] {
                var subscribedTopics = [String]()
                for (topicId, _) in resultSuccess {
                    subscribedTopics.append(topicId)
                }
                completion(.success(subscribedTopics))
                return
            }
            completion(.failure(RequestError.unexpectedResponse))
        }
        
    }
    
}
