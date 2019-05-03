
import Foundation
@testable import Wikipedia
@testable import WMF

class TalkPageTestHelpers {
    
    enum TalkPageJSONType {
        case original
        case updated
        
        var json: Data {
            switch self {
            case .original:
                return """
                {"topics": [
                {
                    "text": "Would you please help me expand the Puppy cat article?",
                    "replies": [
                    {
                    "text": "Hi Pixiu! Glad we were able to meet at the Bay Area Puppercat Edit-a-thon last week. I noticed that the <a href='https://en.wikipedia.org/wiki/Puppy_cat'>Puppy cat</a> could use some more information about ragdolls, do you think that this might be something you'd be interested in contributing to? <a href='https://en.wikipedia.org/wiki/User:Fruzia'>Fruzia</a> (<a href='https://en.wikipedia.org/wiki/User_talk:Fruzia'>talk</a>) 23:08. 20 March 2019 (UTC)",
                    "depth": 0
                    }, {
                    "text": "Hi Fruzia, thanks for reaching out! I'll go and take a look at the article and see what I can contribute with the resources I have at paw <a href='https://en.wikipedia.org/wiki/User:Pixiu'>Pixiu</a> (<a href='https://en.wikipedia.org/wiki/User_talk:Pixiu'>talk</a>) 08:09. 21 March 2019 (UTC)",
                    "depth": 1
                    }
                    ]
                }
                ]}
                """.data(using: .utf8)!
                
            case .updated:
                return """
                    {"topics": [
                        {
                            "text": "Would you please help me expand the Puppy cat article?",
                            "replies": [
                                {
                                    "text": "Hi Pixiu! Glad we were able to meet at the Bay Area Puppercat Edit-a-thon last week. I noticed that the <a href='https://en.wikipedia.org/wiki/Puppy_cat'>Puppy cat</a> could use some more information about ragdolls, do you think that this might be something you'd be interested in contributing to? <a href='https://en.wikipedia.org/wiki/User:Fruzia'>Fruzia</a> (<a href='https://en.wikipedia.org/wiki/User_talk:Fruzia'>talk</a>) 23:08. 20 March 2019 (UTC)",
                                    "depth": 0
                                }, {
                                    "text": "Hi Fruzia, thanks for reaching out! I'll go and take a look at the article and see what I can contribute with the resources I have at paw <a href='https://en.wikipedia.org/wiki/User:Pixiu'>Pixiu</a> (<a href='https://en.wikipedia.org/wiki/User_talk:Pixiu'>talk</a>) 08:09. 21 March 2019 (UTC)",
                                    "depth": 1
                                }, {
                                    "text": "Great! I'm looking forward to seeing your edits. I think that the 'Cool cat's guide to cats' might potentially be a good reference, I think your library has it if I remember correctly. <a href='https://en.wikipedia.org/wiki/User:Fruzia'>Fruzia</a> (<a href='https://en.wikipedia.org/wiki/User_talk:Fruzia'>talk</a>) 14:32. 22 March 2019 (UTC)",
                                    "depth": 2
                                }
                            ]
                        }
                    ]}
                """.data(using: .utf8)!
            }
        }
    }
    
    static func networkTalkPage(for urlString: String, jsonType: TalkPageJSONType = .original, revisionId: Int64) -> NetworkTalkPage? {
        let session = Session.shared
        do {
            let result: NetworkBase = try session.jsonDecodeData(data: jsonType.json)
            let talkPage = NetworkTalkPage(url: URL(string: urlString)!, discussions: result.topics, revisionId: revisionId, displayTitle: "Username", languageCode: "en")
            return talkPage
        } catch {
            return nil
        }
    }
    
}
