import WMFComponents

final class TalkPageCellViewModel: Identifiable {

    var isThreadExpanded: Bool = false
    var isSubscribed: Bool = false

    let topicTitleHtml: String
    let timestamp: Date?
    let timestampDisplay: String?
    let topicName: String

    let id: String
    
    // A cell could contain unsigned content with no replies. In this case the leadComment is nil and otherContentHtml is populated. The subscribe button, metadata row and first reply button will hide.
    let leadComment: TalkPageCellCommentViewModel?
    let otherContentHtml: String?
    
    let replies: [TalkPageCellCommentViewModel]
    
    // Number of users involved in thread
    let activeUsersCount: Int?

    var highlightText: String?
    var activeHighlightResult: TalkPageFindInPageSearchController.SearchResult?

    var repliesCount: Int {
        // Add one for lead comment
        return replies.count + 1
    }
    
    var allCommentViewModels: [TalkPageCellCommentViewModel] {
        if let leadComment = leadComment {
            return replies + [leadComment]
        }
        return replies
    }

    let isUserPermanent: Bool
    
    weak var viewModel: TalkPageViewModel?
    
    init(id: String, topicTitleHtml: String, timestamp: Date?, topicName: String, leadComment: TalkPageCellCommentViewModel?, otherContentHtml: String?, replies: [TalkPageCellCommentViewModel], activeUsersCount: Int?, isUserPermanent: Bool, dateFormatter: DateFormatter?) {
        self.id = id
        self.topicTitleHtml = topicTitleHtml
        self.timestamp = timestamp
        if let timestamp = timestamp {
            self.timestampDisplay = dateFormatter?.string(from: timestamp)
        } else {
            self.timestampDisplay = nil
        }
        self.topicName = topicName
        self.leadComment = leadComment
        
        if let otherContentHtml = otherContentHtml {
            self.otherContentHtml = otherContentHtml
        } else {
            self.otherContentHtml = nil
        }
        
        self.replies = replies
        self.activeUsersCount = activeUsersCount
        self.isUserPermanent = isUserPermanent
    }

    func topicTitleAttributedString(traitCollection: UITraitCollection, theme: Theme = .light) -> NSAttributedString {
        let styles = HtmlUtils.Styles(font: WMFFont.for(.headline, compatibleWith: traitCollection), boldFont: WMFFont.for(.boldHeadline, compatibleWith: traitCollection), italicsFont: WMFFont.for(.headline, compatibleWith: traitCollection), boldItalicsFont: WMFFont.for(.boldHeadline, compatibleWith: traitCollection), color: theme.colors.primaryText, linkColor: theme.colors.link, lineSpacing: 1)
        return NSAttributedString.attributedStringFromHtml(topicTitleHtml, styles: styles)
    }
    
    func leadCommentAttributedString(traitCollection: UITraitCollection, theme: Theme) -> NSAttributedString? {
        if let leadComment = leadComment {
            let commentColor = isThreadExpanded ? theme.colors.primaryText : theme.colors.secondaryText
            let styles = HtmlUtils.Styles(font: WMFFont.for(.callout, compatibleWith: traitCollection), boldFont: WMFFont.for(.boldCallout, compatibleWith: traitCollection), italicsFont: WMFFont.for(.italicCallout, compatibleWith: traitCollection), boldItalicsFont: WMFFont.for(.boldItalicCallout, compatibleWith: traitCollection), color: commentColor, linkColor: theme.colors.link, lineSpacing: 1)
            let leadCommentFormatted = NSMutableAttributedString.mutableAttributedStringFromHtml(leadComment.html, styles: styles).removingInitialNewlineCharacters()

            return leadCommentFormatted
        }
        
        return nil
    }
    
    func otherContentAttributedString(traitCollection: UITraitCollection, theme: Theme) -> NSAttributedString? {
        if let otherContentHtml = otherContentHtml {
            let styles = HtmlUtils.Styles(font: WMFFont.for(.callout, compatibleWith: traitCollection), boldFont: WMFFont.for(.boldCallout, compatibleWith: traitCollection), italicsFont: WMFFont.for(.italicCallout, compatibleWith: traitCollection), boldItalicsFont: WMFFont.for(.boldItalicCallout, compatibleWith: traitCollection), color: theme.colors.primaryText, linkColor: theme.colors.link, lineSpacing: 1)
            return NSMutableAttributedString.mutableAttributedStringFromHtml(otherContentHtml, styles: styles).removingInitialNewlineCharacters()

        }
        
        return nil
    }
}

extension TalkPageCellViewModel: Hashable {
    static func == (lhs: TalkPageCellViewModel, rhs: TalkPageCellViewModel) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

extension TalkPageCellViewModel {

    public func accessibilityDate() -> String? {
        let dateFormatter = DateFormatter.wmf_customVoiceOverTime()

        if let date = timestamp {
            return  dateFormatter?.string(from: date)
        }
        return nil
    }
}
