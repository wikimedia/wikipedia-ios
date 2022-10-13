import Foundation

final class TalkPageCellViewModel {

    var isThreadExpanded: Bool = false
    var isSubscribed: Bool = false

    let topicTitle: String
    let timestamp: Date?
    let topicName: String

    let id: String
    
    let leadComment: TalkPageCellCommentViewModel?
    let otherContent: String?
    
    let replies: [TalkPageCellCommentViewModel]
    // Number of users involved in thread
    let activeUsersCount: String?

    var repliesCount: String {
        // Add one for lead comment
        return "\(replies.count + 1)"
    }
    
    var allCommentViewModels: [TalkPageCellCommentViewModel] {
        if let leadComment = leadComment {
            return replies + [leadComment]
        }
        return replies
    }

    let isUserLoggedIn: Bool
    
    init(id: String, topicTitle: String, timestamp: Date?, topicName: String, leadComment: TalkPageCellCommentViewModel?, otherContent: String?, replies: [TalkPageCellCommentViewModel], activeUsersCount: String?, isUserLoggedIn: Bool) {
        self.id = id
        self.topicTitle = topicTitle
        self.timestamp = timestamp
        self.topicName = topicName
        self.leadComment = leadComment
        self.otherContent = otherContent
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
