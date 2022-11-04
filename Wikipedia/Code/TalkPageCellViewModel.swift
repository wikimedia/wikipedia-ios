import Foundation

final class TalkPageCellViewModel: Identifiable {

    var isThreadExpanded: Bool = false
    var isSubscribed: Bool = false

    let topicTitle: String
    let timestamp: Date?
    let timestampDisplay: String?
    let topicName: String

    let id: String
    
    // A cell could contain unsigned content with no replies. In this case the leadComment is nil and otherContent is populated. The subscribe button, metadata row and first reply button will hide.
    let leadComment: TalkPageCellCommentViewModel?
    let otherContent: String?
    
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

    let isUserLoggedIn: Bool
    
    weak var viewModel: TalkPageViewModel?
    
    init(id: String, topicTitle: String, timestamp: Date?, topicName: String, leadComment: TalkPageCellCommentViewModel?, otherContent: String?, replies: [TalkPageCellCommentViewModel], activeUsersCount: Int?, isUserLoggedIn: Bool, dateFormatter: DateFormatter?) {
        self.id = id
        self.topicTitle = topicTitle
        self.timestamp = timestamp
        if let timestamp = timestamp {
            self.timestampDisplay = dateFormatter?.string(from: timestamp)
        } else {
            self.timestampDisplay = nil
        }
        self.topicName = topicName
        self.leadComment = leadComment
        
        if let otherContent = otherContent {
            self.otherContent = NSMutableAttributedString(string: otherContent).removingInitialNewlineCharacters().string
        } else {
            self.otherContent = nil
        }
        
        self.replies = replies
        self.activeUsersCount = activeUsersCount
        self.isUserLoggedIn = isUserLoggedIn
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
