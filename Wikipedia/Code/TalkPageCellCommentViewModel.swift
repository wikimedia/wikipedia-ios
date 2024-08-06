import WMFComponents

final class TalkPageCellCommentViewModel: Identifiable {

    let commentId: String
    let html: String
    let author: String
    let authorTalkPageURL: String
    let timestamp: Date?
    let replyDepth: Int
    let talkPageURL: URL?
    
    weak var cellViewModel: TalkPageCellViewModel?
    
    init?(commentId: String, html: String?, author: String?, authorTalkPageURL: String, timestamp: Date?, replyDepth: Int?, talkPageURL: URL?) {
        
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
        self.talkPageURL = talkPageURL
    }
    
    func commentAttributedString(traitCollection: UITraitCollection, theme: Theme) -> NSAttributedString {
        let styles = HtmlUtils.Styles(font: WMFFont.for(.callout, compatibleWith: traitCollection), boldFont: WMFFont.for(.boldCallout, compatibleWith: traitCollection), italicsFont: WMFFont.for(.italicCallout, compatibleWith: traitCollection), boldItalicsFont: WMFFont.for(.boldItalicCallout, compatibleWith: traitCollection), color: theme.colors.primaryText, linkColor: theme.colors.link, lineSpacing: 1)

        return NSMutableAttributedString.mutableAttributedStringFromHtml(html, styles: styles).removingInitialNewlineCharacters()
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
