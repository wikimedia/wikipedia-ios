import UIKit
import WMF

class TalkPageViewController: ViewController {

    // MARK: - Properties

    fileprivate let viewModel: TalkPageViewModel
    fileprivate var headerView: TalkPageHeaderView?
    
    fileprivate lazy var shareButton: IconBarButtonItem = IconBarButtonItem(image: UIImage(systemName: "square.and.arrow.up"), style: .plain, target: self, action: #selector(userDidTapShareButton))
    
    fileprivate lazy var findButton: IconBarButtonItem = IconBarButtonItem(image: UIImage(systemName: "doc.text.magnifyingglass"), style: .plain, target: self, action: #selector(userDidTapFindButton))
    
    fileprivate lazy var revisionButton: IconBarButtonItem = IconBarButtonItem(image: UIImage(systemName: "clock.arrow.circlepath"), style: .plain, target: self, action: #selector(userDidTapRevisionButton))
    
    fileprivate lazy var addTopicButton: IconBarButtonItem = IconBarButtonItem(image: UIImage(systemName: "plus"), style: .plain, target: self, action: #selector(userDidTapAddTopicButton))
    
    var talkPageView: TalkPageView {
        return view as! TalkPageView
    }

    // MARK: - Lifecycle

    init(theme: Theme, viewModel: TalkPageViewModel) {
        self.viewModel = viewModel
        super.init(theme: theme)
        
        viewModel.delegate = self
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        let talkPageView = TalkPageView(frame: UIScreen.main.bounds)
        view = talkPageView
        scrollView = talkPageView.collectionView
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.title = WMFLocalizedString("talk-pages-view-title", value: "Talk", comment: "Title of user and article talk pages view.")

        let rightBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "ellipsis.circle"), style: .plain, target: nil, action: nil)
        navigationItem.rightBarButtonItem = rightBarButtonItem
        
        talkPageView.collectionView.dataSource = self
        talkPageView.collectionView.delegate = self
 
        // Needed for reply compose views to display on top of navigation bar.
        navigationController?.setNavigationBarHidden(true, animated: false)
        navigationMode = .forceBar

        viewModel.fetchTalkPage()
        
        setupToolbar()
    }

    private func setupHeaderView() {
        let headerView = TalkPageHeaderView()
        self.headerView = headerView

        headerView.configure(viewModel: viewModel)
        navigationBar.isBarHidingEnabled = false
        navigationBar.isUnderBarViewHidingEnabled = true
        navigationBar.allowsUnderbarHitsFallThrough = true

        navigationBar.addUnderNavigationBarView(headerView, shouldIgnoreSafeArea: true)
        useNavigationBarVisibleHeightForScrollViewInsets = false
        updateScrollViewInsets()

        headerView.apply(theme: theme)
    }

    // MARK: - Public


    // MARK: - Themeable

    override func apply(theme: Theme) {
        super.apply(theme: theme)

        viewModel.theme = theme
        headerView?.apply(theme: theme)
        talkPageView.apply(theme: theme)
        talkPageView.collectionView.reloadData()
        replyComposeController.apply(theme: theme)
    }
    
    // MARK: Reply Compose Management
    
    let replyComposeController = TalkPageReplyComposeController()
    
    override var additionalBottomContentInset: CGFloat {
        return replyComposeController.additionalBottomContentInset
    }
    
    override func keyboardDidChangeFrame(from oldKeyboardFrame: CGRect?, newKeyboardFrame: CGRect?) {
        super.keyboardDidChangeFrame(from: oldKeyboardFrame, newKeyboardFrame: newKeyboardFrame)
        
        guard oldKeyboardFrame != newKeyboardFrame else {
            return
        }
        
        replyComposeController.calculateLayout(in: self, newKeyboardFrame: newKeyboardFrame)
        
        view.setNeedsLayout()
        UIView.animate(withDuration: 0.2) {
            self.view.layoutIfNeeded()
        }
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        headerView?.updateLabelFonts()
        replyComposeController.calculateLayout(in: self)
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        replyComposeController.calculateLayout(in: self, newViewSize: size)
    }
    
    // MARK: Toolbar actions
    
    var talkPageURL: URL? {
        var talkPageURLComponents = URLComponents(url: viewModel.siteURL, resolvingAgainstBaseURL: false)
        talkPageURLComponents?.path = "/wiki/\(viewModel.pageTitle)"
        return talkPageURLComponents?.url
    }

    @objc fileprivate func userDidTapShareButton() {
        guard let talkPageURL = talkPageURL else {
            return
        }
        
        let activityController = UIActivityViewController(activityItems: [talkPageURL], applicationActivities: [TUSafariActivity()])
        present(activityController, animated: true)
    }
    
    @objc fileprivate func userDidTapFindButton() {
        
    }
    
    @objc fileprivate func userDidTapRevisionButton() {
        
    }
    
    @objc fileprivate func userDidTapAddTopicButton() {
        let topicComposeVC = TalkPageTopicComposeViewController(theme: theme)
        let navVC = WMFThemeableNavigationController(rootViewController: topicComposeVC, theme: theme)
        navVC.modalPresentationStyle = .pageSheet
        present(navVC, animated: true, completion: nil)
    }
    
    fileprivate func setupToolbar() {
        enableToolbar()
        setToolbarHidden(false, animated: false)
        
        toolbar.items = [shareButton,  .flexibleSpaceToolbar(), revisionButton, .flexibleSpaceToolbar(), findButton,.flexibleSpaceToolbar(), addTopicButton]
        
        shareButton.accessibilityLabel = WMFLocalizedString("talk-page-share-button", value: "Share talk page", comment: "Title for share talk page button")
        findButton.accessibilityLabel = WMFLocalizedString("talk-page-find-in-page-button", value: "Find in page", comment: "Title for find content in page button")
        revisionButton.accessibilityLabel = WMFLocalizedString("talk-page-revision-button", value: "Revision history", comment: "Title for talk page revision history button")
        addTopicButton.accessibilityLabel = WMFLocalizedString("talk-page-add-topic-button", value: "Add topic", comment: "Title for add topic to talk page button")
    }

}

// MARK: - UICollectionViewDelegate, UICollectionViewDataSource

extension TalkPageViewController: UICollectionViewDelegate, UICollectionViewDataSource {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel.topics.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: TalkPageCell.reuseIdentifier, for: indexPath) as? TalkPageCell else {
             return UICollectionViewCell()
        }

        let viewModel = viewModel.topics[indexPath.row]

        cell.delegate = self
        cell.replyDelegate = self
        
        cell.configure(viewModel: viewModel)
        cell.apply(theme: theme)

        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let cell = collectionView.cellForItem(at: indexPath) as? TalkPageCell else {
            return
        }

        userDidTapDisclosureButton(cellViewModel: cell.viewModel, cell: cell)
    }
    
}

// MARK: - TalkPageCellDelegate

// TODO
extension TalkPageViewController: TalkPageCellDelegate {

    func userDidTapDisclosureButton(cellViewModel: TalkPageCellViewModel?, cell: TalkPageCell) {
        guard let cellViewModel = cellViewModel, let indexOfConfiguredCell = viewModel.topics.firstIndex(where: {$0 === cellViewModel}) else {
            return
        }

        let configuredCellViewModel = viewModel.topics[indexOfConfiguredCell]
        configuredCellViewModel.isThreadExpanded.toggle()
        
        cell.configure(viewModel: configuredCellViewModel)
        talkPageView.collectionView.collectionViewLayout.invalidateLayout()
    }

    func userDidTapSubscribeButton(cellViewModel: TalkPageCellViewModel?, cell: TalkPageCell) {
        guard let cellViewModel = cellViewModel, let indexOfConfiguredCell = viewModel.topics.firstIndex(where: {$0 === cellViewModel}) else {
            return
        }

        let configuredCellViewModel = viewModel.topics[indexOfConfiguredCell]
        configuredCellViewModel.isSubscribed.toggle()
        
        cell.configure(viewModel: configuredCellViewModel)
    }
}

extension TalkPageViewController: TalkPageViewModelDelegate {
    func talkPageDataDidUpdate() {
        setupHeaderView()
        talkPageView.collectionView.reloadData()
    }
}

extension TalkPageViewController: TalkPageCellReplyDelegate {
    func tappedReply(commentViewModel: TalkPageCellCommentViewModel) {
        replyComposeController.setupAndDisplay(in: self, commentViewModel: commentViewModel)
    }
}

extension TalkPageViewController: TalkPageReplyComposeDelegate {
    func tappedClose() {
        replyComposeController.reset()
    }
    
    func tappedPublish(text: String, commentViewModel: TalkPageCellCommentViewModel) {
        // TODO: Publish reply once live data is connected to commentViewModels
    }
}
