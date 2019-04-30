
import Foundation
@testable import Wikipedia
@testable import WMF

class TalkPageTestHelpers {
    
    static func networkTalkPage(for urlString: String, talkPageString: String = "TalkPage", revisionId: Int64) -> NetworkTalkPage? {
        let session = Session.shared
        //todo: better bundle pulling
        guard let json = Bundle(identifier: "org.wikimedia.WikipediaUnitTests")?.wmf_data(fromContentsOfFile: talkPageString, ofType: "json") else {
            return nil
        }
        do {
            let result: [NetworkDiscussion] = try session.jsonDecodeData(data: json)
            let talkPage = NetworkTalkPage(url: URL(string: urlString)!, discussions: result, revisionId: revisionId)
            return talkPage
        } catch {
            return nil
        }
    }
    
}
