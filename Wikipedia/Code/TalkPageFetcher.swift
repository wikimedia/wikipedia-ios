
class NetworkTalkPage {
    let url: URL
    let topics: [NetworkTopic]
    var revisionId: Int?
    let displayTitle: String
    let languageCode: String
    let introText: String?
    
    init(url: URL, topics: [NetworkTopic], revisionId: Int?, displayTitle: String, languageCode: String, introText: String?) {
        self.url = url
        self.topics = topics
        self.revisionId = revisionId
        self.displayTitle = displayTitle
        self.languageCode = languageCode
        self.introText = introText
    }
}

class NetworkBase: Codable {
    let topics: [NetworkTopic]
}

class NetworkTopic:  NSObject, Codable {
    let text: String
    let replies: [NetworkReply]
    let sectionID: Int
    let shas: NetworkTopicShas
    var sort: Int?
    
    enum CodingKeys: String, CodingKey {
        case text
        case shas
        case replies
        case sectionID = "id"
    }
}

class NetworkTopicShas: Codable {
    let text: String
    let indicator: String
}

class NetworkReply: NSObject, Codable {
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

enum TalkPageFetcherError: Error {
    case TalkPageDoesNotExist
}

class TalkPageFetcher: Fetcher {
    
    private let sectionUploader = WikiTextSectionUploader()
    
    func addTopic(to title: String, host: String, languageCode: String, subject: String, body: String, completion: @escaping (Result<[AnyHashable : Any], Error>) -> Void) {
        
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
    
    func addReply(to topic: TalkPageTopic, title: String, host: String, languageCode: String, body: String, completion: @escaping (Result<[AnyHashable : Any], Error>) -> Void) {
        
        guard let url = articleURL(for: title, host: host) else {
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
    
    func fetchTalkPage(urlTitle: String, displayTitle: String, host: String, languageCode: String, revisionID: Int?, completion: @escaping (Result<NetworkTalkPage, Error>) -> Void) {
        
        guard let taskURLWithRevID = taskURL(for: urlTitle, host: host, revisionID: revisionID),
            let taskURLWithoutRevID = taskURL(for: urlTitle, host: host, revisionID: nil) else {
            completion(.failure(RequestError.invalidParameters))
            return
        }
    
        //todo: track tasks/cancel
        session.jsonDecodableTask(with: taskURLWithRevID) { (networkBase: NetworkBase?, response: URLResponse?, error: Error?) in
            
            if let statusCode = (response as? HTTPURLResponse)?.statusCode,
                statusCode == 404 {
                completion(.failure(TalkPageFetcherError.TalkPageDoesNotExist))
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
            //todo performance: should we go back to NSOrderedSets or move sort up into endpoint
            for (topicIndex, topic) in networkBase.topics.enumerated() {
                
                topic.sort = topicIndex
                
                for (replyIndex, reply) in topic.replies.enumerated() {
                    reply.sort = replyIndex
                }
            }

            var introText: String?
            if let firstTopic = networkBase.topics.first,
                firstTopic.text.count == 0,
                let firstReply = firstTopic.replies.first,
                firstReply.text.count > 0 {
                introText = firstReply.text
            }
            
            let filteredTopics = networkBase.topics.filter { $0.text.count > 0 }
            let talkPage = NetworkTalkPage(url: taskURLWithoutRevID, topics: filteredTopics, revisionId: revisionID, displayTitle: displayTitle, languageCode: languageCode, introText: introText)
            completion(.success(talkPage))
        }
    }
    
    func taskURL(for urlTitle: String, host: String) -> URL? {
        return taskURL(for: urlTitle, host: host, revisionID: nil)
    }
}

//MARK: Private

private extension TalkPageFetcher {
    
    func taskURL(for urlTitle: String, host: String, revisionID: Int?) -> URL? {
        
        //note: assuming here urlTitle has already been percent endcoded & escaped
        var pathComponents = ["page", "talk", urlTitle]
        if let revisionID = revisionID {
            pathComponents.append(String(revisionID))
        }
        
        guard let taskURL = configuration.wikipediaTalkPageAPIURLComponentsForHost(host, appending: pathComponents).url else {
            return nil
        }
        
        return taskURL
    }
    
    func articleURL(for urlTitle: String, host: String) -> URL? {
        
        //note: assuming here urlTitle has already been percent endcoded, prefixed & escaped
        let components = configuration.articleURLForHost(host, appending: [urlTitle])
        return components.url
    }
    
}
