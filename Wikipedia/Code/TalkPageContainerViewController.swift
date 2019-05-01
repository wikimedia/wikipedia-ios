
import UIKit

class TalkPageContainerViewController: ViewController {
    
    private var discussionListViewController: TalkPageDiscussionListViewController?
    let talkPageTitle: String
    let host: String
    let titleIncludesPrefix: Bool
    let type: TalkPageType
    let dataStore: MWKDataStore!
    
    private var talkPageController: TalkPageController!
    
    required init(title: String, host: String, titleIncludesPrefix: Bool, type: TalkPageType, dataStore: MWKDataStore) {
        self.talkPageTitle = title
        self.host = host
        self.titleIncludesPrefix = titleIncludesPrefix
        self.type = type
        self.dataStore = dataStore
        super.init()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        navigationBar.isBarHidingEnabled = false
        fetch()
    }
    
    private func fetch() {
        //todo: loading/error/empty states
        talkPageController = TalkPageController(dataStore: dataStore, title: talkPageTitle, host: host, titleIncludesPrefix: titleIncludesPrefix, type: type)
        talkPageController.fetchTalkPage { [weak self] (result) in
            switch result {
            case .success(let talkPage):
                self?.setupDiscussionListViewControllerIfNeeded(with: talkPage)
            case .failure(let error):
                print("error! \(error)")
            }
        }
    }
    
    private func setupDiscussionListViewControllerIfNeeded(with talkPage: TalkPage) {
        if discussionListViewController == nil {
            discussionListViewController = TalkPageDiscussionListViewController(dataStore: dataStore, talkPage: talkPage)
            discussionListViewController?.apply(theme: theme)
            wmf_add(childController: discussionListViewController, andConstrainToEdgesOfContainerView: view, belowSubview: navigationBar)
            discussionListViewController?.delegate = self
        }
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
    func tappedDiscussion(_ discussion: TalkPageDiscussion, viewController: TalkPageDiscussionListViewController) {
        let replyVC = TalkPageReplyContainerViewController.wmf_viewControllerFromTalkPageStoryboard()
        replyVC.dataStore = dataStore
        replyVC.discussion = discussion
        replyVC.apply(theme: theme)
        navigationController?.pushViewController(replyVC, animated: true)
    }
}
