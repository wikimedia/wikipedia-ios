
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
        
        var json: Data {
            
            var fileName: String
            switch self {
            case .original: fileName = "TalkPage-small"
            case .updated: fileName = "TalkPage-small-updated"
            case .smallForPerformance: fileName = "TalkPage-extrasmall"
            case .largeForPerformance: fileName = "TalkPage-large"
            case .largeUpdatedForPerformance: fileName = "TalkPage-large-updated"
            }
            
            guard let json = Bundle(for: XCTestCase.self).wmf_data(fromContentsOfFile: fileName, ofType: "json") else {
                XCTFail("Failure pulling local talk page json")
                return Data()
            }
            
            return json
        
        }
    }
    
    static func networkTalkPage(for urlString: String, jsonType: TalkPageJSONType = .original, revisionId: Int) -> NetworkTalkPage? {
        let session = Session.shared
        
        do {
            let result: NetworkBase = try session.jsonDecodeData(data: jsonType.json)
            
            
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
