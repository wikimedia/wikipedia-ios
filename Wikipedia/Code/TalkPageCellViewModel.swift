import Foundation

final class TalkPageCellViewModel {

    var isThreadExpanded: Bool = false
    var isSubscribed: Bool = false

    let topicTitle: String
    let timestamp: Date?

    let id: String
    var leadComment: TalkPageCellCommentViewModel
    let replies: [TalkPageCellCommentViewModel]
    // Number of users involved in thread
    let activeUsersCount: String

    var repliesCount: String {
        
        // Add one for lead comment
        return "\(replies.count + 1)"
    }
    
    struct CachedCellSize {
        var collapsedHeight: CGFloat?
        var expandedHeight: CGFloat?
        var width: CGFloat
    }
    
    typealias CollectionViewWidth = CGFloat

    var cachedCellSizes: [CollectionViewWidth: CachedCellSize] = [:]
    
    init(id: String, topicTitle: String, timestamp: Date?, leadComment: TalkPageCellCommentViewModel, replies: [TalkPageCellCommentViewModel], activeUsersCount: String) {
        self.id = id
        self.topicTitle = topicTitle
        self.timestamp = timestamp
        self.leadComment = leadComment
        self.replies = replies
        self.activeUsersCount = activeUsersCount
    }
}
