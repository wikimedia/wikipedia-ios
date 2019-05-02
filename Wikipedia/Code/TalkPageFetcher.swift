
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

class NetworkDiscussion: Codable {
    let text: String
    let items: [NetworkDiscussionItem]
}

class NetworkDiscussionItem: Codable {
    let text: String
    let depth: Int16
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
            
            let underscoredTitle = title.replacingOccurrences(of: " ", with: "_")
            let underscoredPrefix = prefix.replacingOccurrences(of: " ", with: "_")
            guard let percentEncodedTitle = (underscoredTitle as NSString).addingPercentEncoding(withAllowedCharacters: CharacterSet.urlPathAllowed) else {
                return nil
            }
            
            return underscoredPrefix + percentEncodedTitle
        } else {
            return title.replacingOccurrences(of: " ", with: "_")
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
        session.jsonDecodableTask(with: taskURLWithRevID) { (discussions: [NetworkDiscussion]?, response: URLResponse?, error: Error?) in
            
            guard !(discussions == nil && error == nil) else {
                completion(.failure(RequestError.unexpectedResponse))
                return
            }
            
            let filteredDiscussions = discussions?.filter { $0.text.count > 0 }
            
            if let filteredDiscussions = filteredDiscussions {
                let talkPage = NetworkTalkPage(url: taskURLWithoutRevID, discussions: filteredDiscussions, revisionId: revisionID, displayTitle: displayTitle, languageCode: languageCode)
                completion(.success(talkPage))
            }
            
            if let error = error {
                completion(.failure(error))
            }
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
}
