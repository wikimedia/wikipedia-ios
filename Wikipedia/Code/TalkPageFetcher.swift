
class NetworkTalkPage {
    var url: URL
    let discussions: [NetworkDiscussion]
    var revisionId: Int64
    
    init(url: URL, discussions: [NetworkDiscussion], revisionId: Int64) {
        self.url = url
        self.discussions = discussions
        self.revisionId = revisionId
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
}

class TalkPageFetcher: Fetcher {
    
    func taskURL(for name: String, host: String, type: TalkPageType) -> URL? {
        return taskURL(for: name, host: host, revisionID: nil, type: type)
    }
    
    func fetchTalkPage(for name: String, host: String, revisionID: Int64, type: TalkPageType, completion: @escaping (Result<NetworkTalkPage, Error>) -> Void) {
        guard let taskURLWithRevID = taskURL(for: name, host: host, revisionID: revisionID, type: type),
        let taskURLWithoutRevID = taskURL(for: name, host: host, revisionID: nil, type: type) else {
            completion(.failure(RequestError.invalidParameters))
            return
        }
    
        //todo: track tasks/cancel
        session.jsonDecodableTask(with: taskURLWithRevID) { (discussions: [NetworkDiscussion]?, response: URLResponse?, error: Error?) in
            
            guard !(discussions == nil && error == nil) else {
                completion(.failure(RequestError.unexpectedResponse))
                return
            }
            
            if let discussions = discussions {
                let talkPage = NetworkTalkPage(url: taskURLWithoutRevID, discussions: discussions, revisionId: revisionID)
                completion(.success(talkPage))
            }
            
            if let error = error {
                completion(.failure(error))
            }
        }
    }
    
    func title(for name: String, type: TalkPageType) -> String? {
        
        let underscoredName = name.replacingOccurrences(of: " ", with: "_")
        //todo: better name handling, or should this happen server-side? See wmf_articleTitlePathComponentAllowed
        guard let percentEncodedName = (underscoredName as NSString).addingPercentEncoding(withAllowedCharacters: CharacterSet.urlPathAllowed) else {
            return nil
        }
        
        let prefix = type == .user ? "User_talk" : "Talk"
        
        return "\(prefix):\(percentEncodedName)"
    }
    
    private func taskURL(for name: String, host: String, revisionID: Int64?, type: TalkPageType) -> URL? {
        
        guard let title = title(for: name, type: type) else {
            return nil
        }
        
        var pathComponents = ["page", "talk", title]
        if let revisionID = revisionID {
            pathComponents.append(String(revisionID))
        }
        
        guard let taskURL = configuration.wikipediaMobileAppsServicesAPIURLComponentsForHost(host, appending: pathComponents).url else {
            return nil
        }
        
        return taskURL
    }
}
