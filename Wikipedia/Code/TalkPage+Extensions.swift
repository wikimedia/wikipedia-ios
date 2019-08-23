
import Foundation

extension TalkPage {
    var isEmpty: Bool {

        guard let topics = topics else {
            return true
        }
        
        if topics.count == 1,
            let firstTopic = topics.anyObject() as? TalkPageTopic,
            firstTopic.isIntro == true {
            return true
        }
        
        return topics.count == 0
    }
}
