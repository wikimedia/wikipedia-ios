
import UIKit

class TalkPageContainerViewController: ViewController {
    
    private var discussionListViewController: TalkPageDiscussionListViewController?
    let talkPageTitle: String
    let host: String
    let languageCode: String
    let titleIncludesPrefix: Bool
    let type: TalkPageType
    let dataStore: MWKDataStore!
    
    private var talkPageController: TalkPageController!
    
    required init(title: String, host: String, languageCode: String, titleIncludesPrefix: Bool, type: TalkPageType, dataStore: MWKDataStore) {
        self.talkPageTitle = title
        self.host = host
        self.languageCode = languageCode
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

        fetch()
        
        let addButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(tappedAdd(_:)))
        navigationItem.rightBarButtonItem = addButton
        navigationBar.updateNavigationItems()
    }
    
    @objc func tappedAdd(_ sender: UIBarButtonItem) {
        let discussionNewVC = TalkPageDiscussionNewViewController.wmf_viewControllerFromTalkPageStoryboard()
        discussionNewVC.delegate = self
        navigationController?.pushViewController(discussionNewVC, animated: true)
    }
    
    private func fetch() {
        //todo: loading/error/empty states
        talkPageController = TalkPageController(dataStore: dataStore, title: talkPageTitle, host: host, languageCode: languageCode, titleIncludesPrefix: titleIncludesPrefix, type: type)
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
    
    override func apply(theme: Theme) {
        super.apply(theme: theme)
        view.backgroundColor = theme.colors.paperBackground
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
