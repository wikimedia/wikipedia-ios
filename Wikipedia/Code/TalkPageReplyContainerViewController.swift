
import UIKit

protocol TalkPageReplyContainerViewControllerDelegate: class {
    func tappedLink(_ url: URL, viewController: TalkPageReplyContainerViewController)
}

class TalkPageReplyContainerViewController: ViewController {
    
    private let replyListContainerView = UIView(frame: .zero)
    private let replyNewContainerView = UIView(frame: .zero)
    private let replyListViewController: TalkPageReplyListViewController
    private let replyNewViewController: TalkPageReplyNewViewController
    
    private let discussion: TalkPageDiscussion
    private let dataStore: MWKDataStore
    
    weak var delegate: TalkPageReplyContainerViewControllerDelegate?
    
    init(discussion: TalkPageDiscussion, dataStore: MWKDataStore) {
        self.discussion = discussion
        self.dataStore = dataStore
        replyListViewController = TalkPageReplyListViewController(dataStore: dataStore, discussion: discussion)
        replyNewViewController = TalkPageReplyNewViewController(dataStore: dataStore, discussion: discussion)
        super.init()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        replyListViewController.delegate = self
        
        wmf_add(childController: replyListViewController, andConstrainToEdgesOfContainerView: replyListContainerView, belowSubview: navigationBar)
        wmf_add(childController: replyNewViewController, andConstrainToEdgesOfContainerView: replyNewContainerView)
        
        addContainerViews()
    }
    
    override func apply(theme: Theme) {
        super.apply(theme: theme)
        view.backgroundColor = theme.colors.paperBackground
        replyListViewController.apply(theme: theme)
        replyNewViewController.apply(theme: theme)
    }

}

private extension TalkPageReplyContainerViewController {
    func addContainerViews() {
        replyNewContainerView.translatesAutoresizingMaskIntoConstraints = false
        replyListContainerView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(replyNewContainerView)
        view.addSubview(replyListContainerView)
        
        NSLayoutConstraint.activate([
            replyNewContainerView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            replyNewContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            replyNewContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])
        NSLayoutConstraint.activate([
            replyListContainerView.bottomAnchor.constraint(equalTo: replyNewContainerView.topAnchor),
            replyListContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            replyListContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            replyListContainerView.topAnchor.constraint(equalTo: view.topAnchor)
        ])
    }
}

extension TalkPageReplyContainerViewController: TalkPageReplyListViewControllerDelegate {
    func tappedLink(_ url: URL, viewController: TalkPageReplyListViewController) {
        delegate?.tappedLink(url, viewController: self)
    }
}
