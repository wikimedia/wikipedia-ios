
import UIKit

protocol TalkPageReplyContainerViewControllerDelegate: class {
    func tappedLink(_ url: URL, viewController: TalkPageReplyContainerViewController)
}

class TalkPageReplyContainerViewController: ViewController {
    
    enum Mode {
        case reply
        case view
    }
    
    weak var delegate: TalkPageReplyContainerViewControllerDelegate?
    
    private let discussion: TalkPageDiscussion
    private let dataStore: MWKDataStore
    private var replyListViewController: TalkPageReplyListViewController!
    private var replyNewViewController: TalkPageDeleteMeViewController!
    
    private var mode: Mode = .view {
        didSet {
            switch mode {
            case .view:
                layoutForViewMode()
            case .reply:
                layoutForReplyMode()
            }
        }
    }
    private var replyContainerHeightConstraint: NSLayoutConstraint!
    private var replyContainerTopConstraint: NSLayoutConstraint!
    private var replyFooterView: UIView?
    
    private var replyModeContentOffset: CGPoint = .zero
    
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
        embedReplyNewViewController()
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        evaluateReplyContainerTopHeightConstraints(for: size)
    }
    
    override func apply(theme: Theme) {
        super.apply(theme: theme)
        view.backgroundColor = theme.colors.paperBackground
    }

}

private extension TalkPageReplyContainerViewController {
    
    func evaluateReplyContainerTopHeightConstraints(for size: CGSize) {
        replyContainerHeightConstraint.constant = size.height * 0.75
        
        switch mode {
        case .reply:
            replyContainerTopConstraint.constant = replyContainerHeightConstraint.constant
        case .view:
            replyContainerTopConstraint.constant = 0
        }
    }
    
    func layoutForReplyMode() {
        
        replyFooterView?.isHidden = true
        
        updateInsetsOffsetsForReplyMode()
        
        evaluateReplyContainerTopHeightConstraints(for: view.bounds.size)
        
        UIView.animate(withDuration: 0.3, delay: 0.0, options: .curveEaseInOut, animations: {
            self.view.layoutIfNeeded()
        }, completion: nil)
    }
    
    func updateInsetsOffsetsForReplyMode() {
        let initialInset = replyListViewController.initialContentInset
        
        replyListViewController.collectionView.contentInset = UIEdgeInsets(top: initialInset.top, left: initialInset.left, bottom: replyContainerHeightConstraint.constant - (replyFooterView?.frame.height ?? 0), right: initialInset.right)
        
        //scroll to bottom
        let scrollView = replyListViewController.collectionView
        let bottomOffset = CGPoint(x: 0, y: scrollView.contentSize.height - scrollView.bounds.size.height + scrollView.adjustedContentInset.bottom)
        replyModeContentOffset = bottomOffset
        scrollView.setContentOffset(replyModeContentOffset, animated: true)
    }
    
    func updateInsetsOffsetsForViewMode() {
        replyListViewController.collectionView.contentInset = replyListViewController.initialContentInset
        
        //scroll to top
        replyListViewController.collectionView.setContentOffset(replyListViewController.initialContentOffset, animated: true)
    }
    
    func layoutForViewMode() {
        
        replyFooterView?.isHidden = true
        
        updateInsetsOffsetsForViewMode()
        
        evaluateReplyContainerTopHeightConstraints(for: view.bounds.size)
        
        UIView.animate(withDuration: 0.3, delay: 0.0, options: .curveEaseInOut, animations: {
            self.view.layoutIfNeeded()
        }, completion: nil)
    }
    
    private func embedListViewController() {
        
        replyListViewController = TalkPageReplyListViewController(dataStore: dataStore, discussion: discussion)
        replyListViewController.delegate = self
        replyListViewController.apply(theme: theme)
        
        wmf_add(childController: replyListViewController, andConstrainToEdgesOfContainerView: view)
    }
    
    private func embedReplyNewViewController() {
        replyNewViewController = TalkPageDeleteMeViewController()
        //replyNewViewController.delegate = self
        
        replyNewViewController.apply(theme: theme)
        
        guard let subview = replyNewViewController.view else {
            return
        }
        
        addChild(replyNewViewController)
        
        view.addSubview(subview)
        
        subview.translatesAutoresizingMaskIntoConstraints = false
        replyContainerTopConstraint = view.bottomAnchor.constraint(equalTo: subview.topAnchor)
        let leftConstraint = subview.leadingAnchor.constraint(equalTo: view.leadingAnchor)
        let rightConstraint = view.trailingAnchor.constraint(equalTo: subview.trailingAnchor)
        replyContainerHeightConstraint = subview.heightAnchor.constraint(equalToConstant: view.bounds.height * 0.75)
        view.addConstraints([replyContainerTopConstraint, leftConstraint, rightConstraint, replyContainerHeightConstraint])
        
        replyNewViewController.didMove(toParent: self)
    }
}

extension TalkPageReplyContainerViewController: TalkPageReplyListViewControllerDelegate {
    func tappedLink(_ url: URL, viewController: TalkPageReplyListViewController) {
        delegate?.tappedLink(url, viewController: self)
    }
    
    func tappedReply(viewController: TalkPageReplyListViewController, footerView: ReplyButtonFooterView) {
        
        replyFooterView = footerView
        mode = mode == .reply ? .view : .reply
    }
    
    func initialInsetOffsetDidChange(for viewController: TalkPageReplyListViewController) {
        switch mode {
        case .view:
            updateInsetsOffsetsForViewMode()
        case .reply:
            updateInsetsOffsetsForReplyMode()
        }
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView, viewController: TalkPageReplyListViewController) {
        guard mode == .reply else {
            return
        }
        
        let delta = max(replyModeContentOffset.y - scrollView.contentOffset.y, 0)
        replyContainerTopConstraint.constant = replyContainerHeightConstraint.constant - delta
    }
}

extension TalkPageReplyContainerViewController: TalkPageUpdateDelegate {
    func tappedPublish(updateType: TalkPageUpdateViewController.UpdateType, subject: String?, body: String, viewController: TalkPageUpdateViewController) {
        //no-op
        //todo: cleanup
    }
}
