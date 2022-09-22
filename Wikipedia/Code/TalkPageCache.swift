import Foundation

struct TalkPageCache: Codable {
    
    var talkPages: Set<TalkPageItem>
    
    init(talkPages: Set<TalkPageItem>) {
        self.talkPages = talkPages
    }
}
