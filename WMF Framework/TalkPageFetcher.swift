
public class NetworkTalkPage: Codable {
    var url: URL! //todo: does this have to be ! if not codable property
    let name: String
    let discussions: [NetworkDiscussion]
    let revisionId: Int64 //todo: unit test this?
    
    private enum CodingKeys: String, CodingKey {
        case name
        case discussions
        case revisionId
    }
}

public class NetworkDiscussion: Codable {
    let title: String
    let items: [NetworkDiscussionItem]
}

public class NetworkDiscussionItem: Codable {
    let text: String
    let depth: Int16 //todo: unit test this?
    let unalteredText: String
}

import Foundation

public class TalkPageFetcher: Fetcher {

    public func fetchTalkPage(for name: String, host: String, priority: Float = URLSessionTask.defaultPriority, completion: @escaping (NetworkTalkPage?, Error?) -> Void) {
        
        //todo: better escaping, or should this happen server-side? See wmf_articleTitlePathComponentAllowed
        guard let escapedName = (name as NSString).addingPercentEncoding(withAllowedCharacters: CharacterSet.urlPathAllowed) else {
            completion(nil, Fetcher.invalidParametersError)
            return
        }
        
        let pathComponents = ["page", "talk", escapedName]
        
        guard let taskURL = configuration.wikipediaMobileAppsServicesAPIURLComponentsForHost(host, appending: pathComponents).url else {
            completion(nil, Fetcher.invalidParametersError)
            return
        }
        
        //The accept profile is case sensitive https://gerrit.wikimedia.org/r/#/c/356429/
        let headers = ["Accept": "application/json; charset=utf-8; profile=\"https://www.mediawiki.org/wiki/Specs/Summary/1.1.2\""]
        session.jsonDecodableTask(with: taskURL, headers: headers, priority: priority) { (talkPage: NetworkTalkPage?, response: URLResponse?, error: Error?) in
            talkPage?.url = taskURL
            completion(talkPage, error)
        }
    }
}
