
class NetworkTalkPage: Codable {
    var url: URL! //todo: does this have to be ! if not codable property
    let name: String
    let discussions: [NetworkDiscussion]
    var revisionId: Int64! //todo: does this have to be ! if not codable property
    
    private enum CodingKeys: String, CodingKey {
        case name
        case discussions
    }
}

class NetworkDiscussion: Codable {
    let title: String
    let items: [NetworkDiscussionItem]
}

class NetworkDiscussionItem: Codable {
    let text: String
    let depth: Int16
}

import Foundation

class TalkPageFetcher: Fetcher {
    
    func taskURL(for name: String, host: String) -> URL? {
        
        //todo: better escaping, or should this happen server-side? See wmf_articleTitlePathComponentAllowed
        guard let escapedName = (name as NSString).addingPercentEncoding(withAllowedCharacters: CharacterSet.urlPathAllowed) else {
            return nil
        }
        
        let pathComponents = ["page", "talk", escapedName]
        
        guard let taskURL = configuration.wikipediaMobileAppsServicesAPIURLComponentsForHost(host, appending: pathComponents).url else {
            return nil
        }
        
        return taskURL
    }
    
    func fetchTalkPage(for name: String, host: String, revisionID: Int64, completion: @escaping (Result<NetworkTalkPage, Error>) -> Void) {
        guard let taskURL = taskURL(for: name, host: host) else {
            completion(.failure(RequestError.invalidParameters))
            return
        }
        
        //todo: append revisionID
    
        //todo: track tasks/cancel
        session.jsonDecodableTask(with: taskURL) { (talkPage: NetworkTalkPage?, response: URLResponse?, error: Error?) in
            
            guard !(talkPage == nil && error == nil) else {
                completion(.failure(RequestError.unexpectedResponse))
                return
            }
            
            if let talkPage = talkPage {
                talkPage.url = taskURL
                talkPage.revisionId = revisionID
                completion(.success(talkPage))
            }
            
            if let error = error {
                completion(.failure(error))
            }
        }
    }
}
