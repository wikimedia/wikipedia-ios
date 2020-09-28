
import Foundation
@testable import Wikipedia
@testable import WMF
import XCTest

class TalkPageTestHelpers {
    
    enum TalkPageJSONType {
        case original
        case updated
        case largeForPerformance
        case smallForPerformance
        case largeUpdatedForPerformance
        
        var fileName: String {
            var fileName: String
            switch self {
            case .original: fileName = "TalkPage-small"
            case .updated: fileName = "TalkPage-small-updated"
            case .smallForPerformance: fileName = "TalkPage-extrasmall"
            case .largeForPerformance: fileName = "TalkPage-large"
            case .largeUpdatedForPerformance: fileName = "TalkPage-large-updated"
            }
            
            return fileName
        }
    }
    
    static func networkTalkPage(for urlString: String, data: Data, revisionId: Int) -> NetworkTalkPage? {
        let session = MWKDataStore.temporary().session
        
        do {
            let result: NetworkBase = try session.jsonDecodeData(data: data)
            
            
            //update sort
            for (topicIndex, topic) in result.topics.enumerated() {
                
                topic.sort = topicIndex
                for (replyIndex, reply) in topic.replies.enumerated() {
                    reply.sort = replyIndex
                }
            }
            
            let talkPage = NetworkTalkPage(url: URL(string: urlString)!, topics: result.topics, revisionId: revisionId, displayTitle: "Username")

            return talkPage
        } catch {
            return nil
        }
    }
}
