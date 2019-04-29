
import UIKit

class TalkPageReplyContainerViewController: ViewController {
    
    var discussion: TalkPageDiscussion!
    var dataStore: MWKDataStore!
    
    private var replyListViewController: TalkPageReplyListViewController!
    private let replyListEmbedSegue = "replyListEmbedSegue"

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let replyListViewController = segue.destination as? TalkPageReplyListViewController,
            segue.identifier == replyListEmbedSegue {
            self.replyListViewController = replyListViewController
            replyListViewController.dataStore = dataStore
            replyListViewController.discussion = discussion
        }
    }

}
