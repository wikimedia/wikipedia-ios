import Foundation

final class TalkPageCellViewModel {

    var isThreadExpanded: Bool = false
    var isSubscribed: Bool = false

    let topicTitle: String
    let timestamp: Date

    var leadComment: TalkPageCellCommentViewModel
    let replies: [TalkPageCellCommentViewModel]
    // Number of users involved in thread
    var activeUsersCount: String = "3"

    var repliesCount: String {
        return "\(replies.count)"
    }
    
    init(topicTitle: String, timestamp: Date, leadComment: TalkPageCellCommentViewModel, replies: [TalkPageCellCommentViewModel], activeUsersCount: String) {
        self.topicTitle = topicTitle
        self.timestamp = timestamp
        self.leadComment = leadComment
        self.replies = replies
        self.activeUsersCount = activeUsersCount
    }
}
