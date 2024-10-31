import Foundation
import WMF
import WMFData

struct TalkPageAPIResponse: Codable {
    let threads: TalkPageThreadItems?
    
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
    let author: String?
    let timestamp: Date?
    
    enum CodingKeys: String, CodingKey {
        case type, level, id, html, name ,headingLevel, replies, author, timestamp
        case otherContent = "othercontent"
    }
    
    enum TalkPageItemType: String, Codable {
        case comment = "comment"
        case heading = "heading"
    }
    
    init(type: TalkPageItemType, level: Int?, id: String, html: String?, name: String?, headingLevel: Int?, replies: [TalkPageItem], otherContent: String?, author: String?, timestamp: Date?) {
        self.type = type
        self.level = level
        self.id = id
        self.html = html
        self.name = name
        self.headingLevel = headingLevel
        self.replies = replies
        self.otherContent = otherContent
        self.author = author
        self.timestamp = timestamp
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        
        type = try values.decode(TalkPageItemType.self, forKey: .type)
        level = try? values.decode(Int.self, forKey: .level)
        id = try values.decode(String.self, forKey: .id)
        html = try? values.decode(String.self, forKey: .html)
        name = try? values.decode(String.self, forKey: .name)
        headingLevel = try? values.decode(Int.self, forKey: .headingLevel)
        replies = (try? values.decode([TalkPageItem].self, forKey: .replies)) ?? []
        otherContent = try? values.decode(String.self, forKey: .otherContent)
        author = try? values.decode(String.self, forKey: .author)
  
        if let timestampString = try? values.decode(String.self, forKey: .timestamp) {
            let timestampDate = (timestampString as NSString).wmf_iso8601Date()
            timestamp = timestampDate
        } else {
            timestamp = nil
        }
    }
    
    func updatingReplies(replies: [TalkPageItem]) -> TalkPageItem {
        return TalkPageItem(type: type, level: level, id: id, html: html, name: name, headingLevel: headingLevel, replies: replies, otherContent: otherContent, author: author, timestamp: timestamp)
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
                completion(.success(talk.threads?.threadItems ?? []))                
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }
    
    ///  This function takes a **topic** argument of type String.
    ///  This argument expects a `name` value from `TalkPageItem` heading (or topic) items.
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
    
    /// Returns a list of active talk page topics subscription
    /// - Parameters:
    ///   - siteURL: URL for the talk page, takes a URL object
    ///   - topics: Expects a array of Strings containing the `name` value from `TalkPageItem`
    ///   - completion: Returns either and array with the the `name` property of subscribed topics or an Error
    func getSubscribedTopics(siteURL: URL, topics: [String], completion: @escaping (Result<[String], Error>) -> Void) {
        
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
                for (topicId, subStatus) in resultSuccess {
                    if subStatus as? Int == 1 {
                        subscribedTopics.append(topicId)
                    }
                }
                completion(.success(subscribedTopics))
                return
            }
            completion(.failure(RequestError.unexpectedResponse))
        }
    }
    
    func postReply(talkPageTitle: String, siteURL: URL, commentId: String, comment: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let title = talkPageTitle.denormalizedPageTitle else {
            completion(.failure(RequestError.invalidParameters))
            return
        }
        
        let params = ["action": "discussiontoolsedit",
                      "paction": "addcomment",
                      "page": title,
                      "matags": WMFEditTag.appTalkReply.rawValue,
                      "format": "json",
                      "formatversion" : "2",
                      "commentid": commentId,
                      "wikitext": comment
                      
        ]
        
        performTokenizedMediaWikiAPIPOST(to: siteURL, with: params, reattemptLoginOn401Response: false) { result, httpResponse, error in
            self.evaluateResponse(error, result, completion: completion)
        }
    }
    
    func postTopic(talkPageTitle: String, siteURL: URL, topicTitle: String, topicBody: String, completion: @escaping (Result<Void, Error>) -> Void) {
        
        guard let title = talkPageTitle.denormalizedPageTitle else {
            completion(.failure(RequestError.invalidParameters))
            return
        }
        
        let params = ["action": "discussiontoolsedit",
                      "paction": "addtopic",
                      "page": title,
                      "matags": WMFEditTag.appTalkTopic.rawValue,
                      "format": "json",
                      "formatversion" : "2",
                      "sectiontitle": topicTitle,
                      "wikitext": topicBody        ]
        
        performTokenizedMediaWikiAPIPOST(to: siteURL, with: params, reattemptLoginOn401Response: false) { result, httpResponse, error in
            self.evaluateResponse(error, result, completion: completion)
        }
    }
    
    fileprivate func evaluateResponse(_ error: Error?, _ result: [String : Any]?, completion: @escaping (Result<Void, Error>) -> Void) {
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
