import Foundation

final class TalkPageCellViewModel {

    // TODO: - From Data Controller
    var isThreadExpanded: Bool = false
    var isSubscribed: Bool = false

    var topicTitle = "This is title of the topic. It's long enough that it truncates when the thread is collapsed, but expands and displays fully when the thread is expanded."
    var timestamp = Date()

    var leadComment: TalkPageCellCommentViewModel = TalkPageCellCommentViewModel()
    var replies: [TalkPageCellCommentViewModel] = [TalkPageCellCommentViewModel(), TalkPageCellCommentViewModel(), TalkPageCellCommentViewModel()]

    // Number of users involved in thread
    var activeUsersCount: String = "3"

    var repliesCount: String {
        return "\(replies.count)"
    }
    
}
