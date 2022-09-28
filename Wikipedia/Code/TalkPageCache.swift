import Foundation

struct TalkPageCache: Codable {
    
    var talkPages: [TalkPageItem]
    
    init(talkPages: [TalkPageItem]) {
        self.talkPages = talkPages
    }
}
