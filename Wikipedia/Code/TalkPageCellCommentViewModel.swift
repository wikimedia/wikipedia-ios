import Foundation

final class TalkPageCellCommentViewModel {

    // TODO: From Data Controller
    var text: String = "This is a reply. Let's see how it looks when it spans multiple lines. And maybe even some more lines. Like the topic title, it truncates after a few lines but displays fully when the thread is expanded."
    var author: String = "Username"
    var authorTalkPageURL = ""
    var timestamp = Date()
    var replyDepth: Int = Int.random(in: 0...5)

}
