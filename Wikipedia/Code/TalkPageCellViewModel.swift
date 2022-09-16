import Foundation

final class TalkPageCellViewModel {

    var isThreadExpanded: Bool = false
    var isSubscribed: Bool = false

    let topicTitle: String
    let timestamp: Date?
    let topicName: String

    var leadComment: TalkPageCellCommentViewModel
    let replies: [TalkPageCellCommentViewModel]
    // Number of users involved in thread
    let activeUsersCount: String

    var repliesCount: String {
        
        // Add one for lead comment
        return "\(replies.count + 1)"
    }
    
    init(topicTitle: String, timestamp: Date?, topicName: String, leadComment: TalkPageCellCommentViewModel, replies: [TalkPageCellCommentViewModel], activeUsersCount: String) {
        self.topicTitle = topicTitle
        self.timestamp = timestamp
        self.topicName = topicName
        self.leadComment = leadComment
        self.replies = replies
        self.activeUsersCount = activeUsersCount
    }
}
