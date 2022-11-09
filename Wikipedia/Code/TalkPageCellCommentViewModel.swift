import Foundation

final class TalkPageCellCommentViewModel: Identifiable {

    let commentId: String
    let html: String
    let author: String
    let authorTalkPageURL: String
    let timestamp: Date?
    let replyDepth: Int
    
    weak var cellViewModel: TalkPageCellViewModel?
    
    init?(commentId: String, html: String?, author: String?, authorTalkPageURL: String, timestamp: Date?, replyDepth: Int?) {
        
        guard let html = html,
              let author = author,
              let replyDepth = replyDepth else {
            return nil
        }
        
        self.commentId = commentId
        self.html = html
        self.author = author
        self.authorTalkPageURL = authorTalkPageURL
        self.timestamp = timestamp
        self.replyDepth = replyDepth
    }
    
    func commentAttributedString(traitCollection: UITraitCollection, theme: Theme) -> NSAttributedString {
        return html.byAttributingHTML(with: .callout, boldWeight: .semibold, matching: traitCollection, color: theme.colors.primaryText, linkColor: theme.colors.link, handlingLists: true, handlingSuperSubscripts: true).removingInitialNewlineCharacters()
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
