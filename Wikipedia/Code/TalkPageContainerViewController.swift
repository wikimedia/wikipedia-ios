
import UIKit

class TalkPageContainerViewController: ViewController {
    
    private var discussionListViewController: TalkPageDiscussionListViewController?
    var name: String!
    var host: String = "en.wikipedia.org" //todo: smart host
    var type: TalkPageType!
    var dataStore: MWKDataStore!
    
    private var talkPageController: TalkPageController!
    
    required init(name: String, host: String, dataStore: MWKDataStore, type: TalkPageType) {
        self.name = name
        self.host = host
        self.dataStore = dataStore
        self.type = type
        super.init()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .white
        fetch()
    }
    
    private func fetch() {
        //todo: loading/error/empty states
        talkPageController = TalkPageController(dataStore: dataStore, name: name, host: host, type: type)
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
        navigationController?.pushViewController(replyVC, animated: true)
    }
}
