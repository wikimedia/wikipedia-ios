import Foundation

final class TalkPageCellCommentViewModel: Identifiable {

    let commentId: String
    let text: String
    let author: String
    let authorTalkPageURL: String
    let timestamp: Date?
    let replyDepth: Int
    
    weak var cellViewModel: TalkPageCellViewModel?
    
    init?(commentId: String, text: String?, author: String?, authorTalkPageURL: String, timestamp: Date?, replyDepth: Int?) {
        
        guard let text = text,
              let author = author,
              let replyDepth = replyDepth else {
            return nil
        }
        
        self.commentId = commentId
        self.text = NSMutableAttributedString(string: text).removingInitialNewlineCharacters().string
        self.author = author
        self.authorTalkPageURL = authorTalkPageURL
        self.timestamp = timestamp
        self.replyDepth = replyDepth
    }
}

extension TalkPageCellCommentViewModel: Hashable {
    static func == (lhs: TalkPageCellCommentViewModel, rhs: TalkPageCellCommentViewModel) -> Bool {
        lhs.commentId == rhs.commentId
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(commentId)
    }
}
