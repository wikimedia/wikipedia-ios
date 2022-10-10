import Foundation

struct TalkPageCache: Codable {
    
    var talkPageItems: [TalkPageItem]
    
    init(talkPages: [TalkPageItem]) {
        self.talkPageItems = talkPages
    }
}
