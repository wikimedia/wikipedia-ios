
class NetworkTalkPage {
    let url: URL
    let discussions: [NetworkDiscussion]
    let revisionId: Int64
    let displayTitle: String
    let languageCode: String
    
    init(url: URL, discussions: [NetworkDiscussion], revisionId: Int64, displayTitle: String, languageCode: String) {
        self.url = url
        self.discussions = discussions
        self.revisionId = revisionId
        self.displayTitle = displayTitle
        self.languageCode = languageCode
    }
}

class NetworkBase: Codable {
    let topics: [NetworkDiscussion]
}

class NetworkDiscussion:  NSObject, Codable {
    let text: String
    let items: [NetworkDiscussionItem]
    let sectionID: Int
    let shas: NetworkDiscussionShas
    var sort: Int!
    
    enum CodingKeys: String, CodingKey {
        case text
        case shas
        case items = "replies"
        case sectionID = "id"
    }
}

class NetworkDiscussionShas: Codable {
    let text: String
    let replies: String
}

class NetworkDiscussionItem: NSObject, Codable {
    let text: String
    let depth: Int16
    let sha: String
    var sort: Int!
    
    enum CodingKeys: String, CodingKey {
        case text
        case depth
        case sha
    }
}

import Foundation

enum TalkPageType {
    case user
    case article
    
    var prefix: String {
        switch self {
        case .user:
            return "User talk:"
        case .article:
            return "Talk:"
        }
    }
    
    func urlTitle(for title: String, titleIncludesPrefix: Bool) -> String? {
        if !titleIncludesPrefix {

            guard let underscoredTitle = title.wmf_denormalizedPageTitle(),
                let underscoredPrefix = prefix.wmf_denormalizedPageTitle(),
                let percentEncodedTitle = underscoredTitle.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlPathAllowed) else {
                return nil
            }
            
            return underscoredPrefix + percentEncodedTitle
        } else {
            return title.wmf_denormalizedPageTitle()
        }
    }
    
    func displayTitle(for title: String, titleIncludesPrefix: Bool) -> String {
        if !titleIncludesPrefix {
            return title
        }
        
        //todo: There will be some language issues with this
        return title.replacingOccurrences(of: prefix, with: "")
    }
}

class TalkPageFetcher: Fetcher {
    
    private let sectionUploader = WikiTextSectionUploader()
    
    func addDiscussion(to title: String, host: String, languageCode: String, subject: String, body: String, completion: @escaping (Result<[AnyHashable : Any], Error>) -> Void) {
        
        guard let url = articleURL(for: title, host: host) else {
            completion(.failure(RequestError.invalidParameters))
            return
        }
        
        sectionUploader.addSection(withSummary: subject, text: body, forArticleURL: url) { (result, error) in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let result = result else {
                completion(.failure(RequestError.unexpectedResponse))
                return
            }
            
            completion(.success(result))
        }
    }
    
    func addReply(to discussion: TalkPageDiscussion, title: String, host: String, languageCode: String, body: String, completion: @escaping (Result<[AnyHashable : Any], Error>) -> Void) {
        
        guard let url = articleURL(for: title, host: host) else {
            completion(.failure(RequestError.invalidParameters))
            return
        }
        //todo: should sectionID in CoreData be string?
        sectionUploader.append(toSection: String(discussion.sectionID), text: body, forArticleURL: url) { (result, error) in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let result = result else {
                completion(.failure(RequestError.unexpectedResponse))
                return
            }
            
            completion(.success(result))
        }
    }
    
    func taskURL(for urlTitle: String, host: String) -> URL? {
        return taskURL(for: urlTitle, host: host, revisionID: nil)
    }
    
    func fetchTalkPage(urlTitle: String, displayTitle: String, host: String, languageCode: String, revisionID: Int64, completion: @escaping (Result<NetworkTalkPage, Error>) -> Void) {
        guard let taskURLWithRevID = taskURL(for: urlTitle, host: host, revisionID: revisionID),
            let taskURLWithoutRevID = taskURL(for: urlTitle, host: host, revisionID: nil) else {
            completion(.failure(RequestError.invalidParameters))
            return
        }
    
        //todo: track tasks/cancel
        session.jsonDecodableTask(with: taskURLWithRevID) { (networkBase: NetworkBase?, response: URLResponse?, error: Error?) in

            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let networkBase = networkBase else {
                completion(.failure(RequestError.unexpectedResponse))
                return
            }
            
            //update sort
            for (topicIndex, topic) in networkBase.topics.enumerated() {
                
                topic.sort = topicIndex
                for (replyIndex, reply) in topic.items.enumerated() {
                    reply.sort = replyIndex
                }
            }
            
            let filteredDiscussions = networkBase.topics.filter { $0.text.count > 0 }
            
            let talkPage = NetworkTalkPage(url: taskURLWithoutRevID, discussions: filteredDiscussions, revisionId: revisionID, displayTitle: displayTitle, languageCode: languageCode)
            completion(.success(talkPage))
        }
    }
    
    private func taskURL(for urlTitle: String, host: String, revisionID: Int64?) -> URL? {
        
        //note: assuming here urlTitle has already been percent endcoded & escaped
        var pathComponents = ["page", "talk", urlTitle]
        if let revisionID = revisionID {
            pathComponents.append(String(revisionID))
        }
        
        guard let taskURL = configuration.wikipediaMobileAppsServicesAPIURLComponentsForHost(host, appending: pathComponents).url else {
            return nil
        }
        
        return taskURL
    }
    
    private func articleURL(for urlTitle: String, host: String) -> URL? {
        
        //note: assuming here urlTitle has already been percent endcoded, prefixed & escaped
        let components = configuration.articleURLForHost(host, appending: [urlTitle])
        return components.url
    }
}
