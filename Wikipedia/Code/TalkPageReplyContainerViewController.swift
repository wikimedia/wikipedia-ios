
import UIKit

protocol TalkPageReplyContainerViewControllerDelegate: class {
    func tappedLink(_ url: URL, viewController: TalkPageReplyContainerViewController)
}

class TalkPageReplyContainerViewController: ViewController {

    weak var delegate: TalkPageReplyContainerViewControllerDelegate?
    
    private let discussion: TalkPageDiscussion
    private let dataStore: MWKDataStore
    private var replyListViewController: TalkPageReplyListViewController!

    
    required init(dataStore: MWKDataStore, discussion: TalkPageDiscussion) {
        self.dataStore = dataStore
        self.discussion = discussion
        
        super.init()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationBar.isBarHidingEnabled = false

        embedListViewController()
    }
    
    override func apply(theme: Theme) {
        super.apply(theme: theme)
        view.backgroundColor = theme.colors.paperBackground
    }

}

private extension TalkPageReplyContainerViewController {

    private func embedListViewController() {
        
        replyListViewController = TalkPageReplyListViewController(dataStore: dataStore, discussion: discussion)
        replyListViewController.delegate = self
        replyListViewController.apply(theme: theme)
        
        wmf_add(childController: replyListViewController, andConstrainToEdgesOfContainerView: view)
    }
}

extension TalkPageReplyContainerViewController: TalkPageReplyListViewControllerDelegate {
    func initialInsetOffsetDidChange(for viewController: TalkPageReplyListViewController) {
        //no-op
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView, viewController: TalkPageReplyListViewController) {
        //no-op
    }
    
    func composeTextDidChange(_ viewController: TalkPageReplyListViewController) {
        //todo: mess with navigation items
    }
    
    func tappedLink(_ url: URL, viewController: TalkPageReplyListViewController) {
        delegate?.tappedLink(url, viewController: self)
    }
    
    func tappedReply(viewController: TalkPageReplyListViewController, footerView: ReplyButtonFooterView) {

    }
}

extension TalkPageReplyContainerViewController: TalkPageUpdateStackViewDelegate {
    func textDidChange() {
        //no-op yet
    }
}
