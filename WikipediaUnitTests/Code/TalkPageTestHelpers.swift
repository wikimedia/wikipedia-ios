
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
                    "id": 0,
                    "html": "Would you please help me expand the Puppy cat article?",
                    "replies": [
                    {
                    "html": "Hi Pixiu! Glad we were able to meet at the Bay Area Puppercat Edit-a-thon last week. I noticed that the <a href='https://en.wikipedia.org/wiki/Puppy_cat'>Puppy cat</a> could use some more information about ragdolls, do you think that this might be something you'd be interested in contributing to? <a href='https://en.wikipedia.org/wiki/User:Fruzia'>Fruzia</a> (<a href='https://en.wikipedia.org/wiki/User_talk:Fruzia'>talk</a>) 23:08. 20 March 2019 (UTC)",
                    "depth": 0,
                    "sha": "ad47492",
                    "sort": 0
                    }, {
                    "html": "Hi Fruzia, thanks for reaching out! I'll go and take a look at the article and see what I can contribute with the resources I have at paw <a href='https://en.wikipedia.org/wiki/User:Pixiu'>Pixiu</a> (<a href='https://en.wikipedia.org/wiki/User_talk:Pixiu'>talk</a>) 08:09. 21 March 2019 (UTC)",
                    "depth": 1,
                    "sha": "3602ec3",
                    "sort": 1
                    }
                    ],
                    "shas": {
                        "html": "5a5bd8e",
                        "indicator": "asdfgjl"
                    },
                    "sort": 0
                }
                ]}
                """.data(using: .utf8)!
                
            case .updated:
                return """
                    {"topics": [
                        {
                            "id": 0,
                            "html": "Would you please help me expand the Puppy cat article?",
                            "replies": [
                                {
                                    "html": "Hi Pixiu! Glad we were able to meet at the Bay Area Puppercat Edit-a-thon last week. I noticed that the <a href='https://en.wikipedia.org/wiki/Puppy_cat'>Puppy cat</a> could use some more information about ragdolls, do you think that this might be something you'd be interested in contributing to? <a href='https://en.wikipedia.org/wiki/User:Fruzia'>Fruzia</a> (<a href='https://en.wikipedia.org/wiki/User_talk:Fruzia'>talk</a>) 23:08. 20 March 2019 (UTC)",
                                    "depth": 0,
                                    "sha": "ad47492",
                                    "sort": 0
                                }, {
                                    "html": "Hi Fruzia, thanks for reaching out! I'll go and take a look at the article and see what I can contribute with the resources I have at paw <a href='https://en.wikipedia.org/wiki/User:Pixiu'>Pixiu</a> (<a href='https://en.wikipedia.org/wiki/User_talk:Pixiu'>talk</a>) 08:09. 21 March 2019 (UTC)",
                                    "depth": 1,
                                    "sha": "3602ec3",
                                    "sort": 1
                                }, {
                                    "html": "Great! I'm looking forward to seeing your edits. I think that the 'Cool cat's guide to cats' might potentially be a good reference, I think your library has it if I remember correctly. <a href='https://en.wikipedia.org/wiki/User:Fruzia'>Fruzia</a> (<a href='https://en.wikipedia.org/wiki/User_talk:Fruzia'>talk</a>) 14:32. 22 March 2019 (UTC)",
                                    "depth": 2,
                                    "sha": "438bfc2",
                                    "sort": 2
                                }
                            ],
                            "shas": {
                                "html": "5a5bd8e",
                                "indicator": "not_asdfgjl"
                            },
                            "sort": 0
                        }
                    ]}
                """.data(using: .utf8)!
            }
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
