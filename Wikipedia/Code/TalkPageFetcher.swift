
class NetworkTalkPage {
    let url: URL
    let topics: [NetworkTopic]
    var revisionId: Int?
    let displayTitle: String
    let introText: String?
    
    init(url: URL, topics: [NetworkTopic], revisionId: Int?, displayTitle: String, introText: String?) {
        self.url = url
        self.topics = topics
        self.revisionId = revisionId
        self.displayTitle = displayTitle
        self.introText = introText
    }
}

class NetworkBase: Codable {
    let topics: [NetworkTopic]
}

class NetworkTopic:  NSObject, Codable {
    let html: String
    let replies: [NetworkReply]
    let sectionID: Int
    let shas: NetworkTopicShas
    var sort: Int?
    
    enum CodingKeys: String, CodingKey {
        case html
        case shas
        case replies
        case sectionID = "id"
    }
}

class NetworkTopicShas: Codable {
    let html: String
    let indicator: String
}

class NetworkReply: NSObject, Codable {
    let html: String
    let depth: Int16
    let sha: String
    var sort: Int!
    
    enum CodingKeys: String, CodingKey {
        case html
        case depth
        case sha
    }
}

import Foundation
import WMF

enum TalkPageType {
    case user
    case article
    
    func canonicalNamespacePrefix(for siteURL: URL) -> String? {
        
        //todo: PageNamespace
        var namespaceRaw: String
        switch self {
        case .article:
            namespaceRaw = "1"
        case .user:
            namespaceRaw = "3"
        }
        
        guard let namespace = MWKLanguageLinkController.sharedInstance().language(forSiteURL: siteURL)?.namespaces?[namespaceRaw] else {
            return nil
        }
        
        return namespace.canonicalName + ":"
    }
    
    func titleWithCanonicalNamespacePrefix(title: String, siteURL: URL) -> String {
        return (canonicalNamespacePrefix(for: siteURL) ?? "") + title
    }
    
    func titleWithoutNamespacePrefix(title: String) -> String {
        if let firstColon = title.range(of: ":") {
            var returnTitle = title
            returnTitle.removeSubrange(title.startIndex..<firstColon.upperBound)
            return returnTitle
        } else {
            return title
        }
    }
    
    func urlTitle(for title: String) -> String? {
        assert(title.contains(":"), "Title must already be prefixed with namespace.")
        return title.wmf_denormalizedPageTitle()
    }
}

enum TalkPageFetcherError: Error {
    case talkPageDoesNotExist
}

class TalkPageFetcher: Fetcher {
    
    private let sectionUploader = WikiTextSectionUploader()
    
    func addTopic(to title: String, siteURL: URL, subject: String, body: String, completion: @escaping (Result<[AnyHashable : Any], Error>) -> Void) {
        
        guard let url = postURL(for: title, siteURL: siteURL) else {
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
    
    func addReply(to topic: TalkPageTopic, title: String, siteURL: URL, body: String, completion: @escaping (Result<[AnyHashable : Any], Error>) -> Void) {
        
        guard let url = postURL(for: title, siteURL: siteURL) else {
            completion(.failure(RequestError.invalidParameters))
            return
        }
        
        //todo: should sectionID in CoreData be string?
        sectionUploader.append(toSection: String(topic.sectionID), text: body, forArticleURL: url) { (result, error) in
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
    
    func fetchTalkPage(urlTitle: String, displayTitle: String, siteURL: URL, revisionID: Int?, completion: @escaping (Result<NetworkTalkPage, Error>) -> Void) {
        
        guard let taskURLWithRevID = getURL(for: urlTitle, siteURL: siteURL, revisionID: revisionID),
            let taskURLWithoutRevID = getURL(for: urlTitle, siteURL: siteURL, revisionID: nil) else {
            completion(.failure(RequestError.invalidParameters))
            return
        }
    
        //todo: track tasks/cancel
        session.jsonDecodableTask(with: taskURLWithRevID) { (networkBase: NetworkBase?, response: URLResponse?, error: Error?) in
            
            if let statusCode = (response as? HTTPURLResponse)?.statusCode,
                statusCode == 404 {
                completion(.failure(TalkPageFetcherError.talkPageDoesNotExist))
                return
            }
            
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let networkBase = networkBase else {
                completion(.failure(RequestError.unexpectedResponse))
                return
            }
            
            //update sort
            //todo performance: should we go back to NSOrderedSets or move sort up into endpoint?
            for (topicIndex, topic) in networkBase.topics.enumerated() {
                
                topic.sort = topicIndex
                
                for (replyIndex, reply) in topic.replies.enumerated() {
                    reply.sort = replyIndex
                }
            }

            var introText: String?
            if let firstTopic = networkBase.topics.first,
                firstTopic.html.count == 0,
                let firstReply = firstTopic.replies.first,
                firstReply.html.count > 0 {
                introText = firstReply.html
            }
            
            let filteredTopics = networkBase.topics.filter { $0.html.count > 0 }
            let talkPage = NetworkTalkPage(url: taskURLWithoutRevID, topics: filteredTopics, revisionId: revisionID, displayTitle: displayTitle, introText: introText)
            completion(.success(talkPage))
        }
    }
    
    func getURL(for urlTitle: String, siteURL: URL) -> URL? {
        return getURL(for: urlTitle, siteURL: siteURL, revisionID: nil)
    }
}

//MARK: Private

private extension TalkPageFetcher {
    
    func getURL(for urlTitle: String, siteURL: URL, revisionID: Int?) -> URL? {
        
        assert(urlTitle.contains(":"), "Title must already be prefixed with namespace.")
        
        guard let host = siteURL.host,
        let percentEncodedUrlTitle = urlTitle.addingPercentEncoding(withAllowedCharacters: .wmf_articleTitlePathComponentAllowed) else {
            return nil
        }
        
        var pathComponents = ["page", "talk", percentEncodedUrlTitle]
        if let revisionID = revisionID {
            pathComponents.append(String(revisionID))
        }
        
        guard let taskURL = configuration.wikipediaTalkPageAPIURLComponentsForHost(host, appending: pathComponents).url else {
            return nil
        }
        
        return taskURL
    }
    
    func postURL(for urlTitle: String, siteURL: URL) -> URL? {
        
        assert(urlTitle.contains(":"), "Title must already be prefixed with namespace.")
        
        guard let host = siteURL.host else {
            return nil
        }
        
        let components = configuration.articleURLForHost(host, appending: [urlTitle])
        return components.url
    }
    
}
