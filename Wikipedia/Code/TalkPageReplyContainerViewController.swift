
import UIKit

class TalkPageReplyContainerViewController: ViewController {
    
    @IBOutlet private var replyListContainerView: UIView!
    
    var discussion: TalkPageDiscussion!
    var dataStore: MWKDataStore!
    
    private var replyListViewController: TalkPageReplyListViewController?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard discussion != nil,
            dataStore != nil else {
                assertionFailure("TalkPageReplyContainerViewController needs dataStore and discussion to function.")
                return
        }

        replyListViewController = TalkPageReplyListViewController(dataStore: dataStore, discussion: discussion)
        wmf_add(childController: replyListViewController, andConstrainToEdgesOfContainerView: replyListContainerView)
    }

}
