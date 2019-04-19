
import UIKit

class TalkPageContainerViewController: ViewController {
    
    private var discussionListViewController: TalkPageDiscussionListViewController!
    var talkPageName: String!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard segue.identifier == "discussionListEmbedSegue", let listVC = segue.destination as? TalkPageDiscussionListViewController else {
            return
        }
        
        discussionListViewController = listVC
        discussionListViewController.delegate = self
    }
    
    @IBAction func tappedAddButton(_ sender: UIBarButtonItem) {
        let discussionNewVC = TalkPageDiscussionNewViewController.wmf_viewControllerFromTalkPageStoryboard()
        discussionNewVC.delegate = self
        navigationController?.pushViewController(discussionNewVC, animated: true)
    }

}

extension TalkPageContainerViewController: TalkPageDiscussionNewDelegate {
    func addDiscussion(viewController: TalkPageDiscussionNewViewController) {
        navigationController?.popViewController(animated: true)
    }
}

extension TalkPageContainerViewController: TalkPageDiscussionListDelegate {
    func tappedDiscussion(viewController: TalkPageDiscussionListViewController) {
        let replyVC = TalkPageReplyContainerViewController.wmf_viewControllerFromTalkPageStoryboard()
        navigationController?.pushViewController(replyVC, animated: true)
    }
}
