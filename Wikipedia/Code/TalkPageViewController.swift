import UIKit
import WMF

class TalkPageViewController: ViewController {

    // MARK: - Properties

    fileprivate let viewModel: TalkPageViewModel
    fileprivate var headerView: TalkPageHeaderView?

    var talkPageView: TalkPageView {
        return view as! TalkPageView
    }
    
    // MARK: - Overflow menu properties
    
    fileprivate var userTalkOverflowSubmenuActions: [UIAction] {
        let contributionsAction = UIAction(title: "contributions", image: UIImage(systemName: "star"), handler: { _ in
            print("hi")
        })

        let userGroupsAction = UIAction(title: "user groups", image: UIImage(systemName: "star"), handler: { _ in
            print("hi")
        })

        let logsAction = UIAction(title: "logs", image: UIImage(systemName: "star"), handler: { _ in
            print("hi")
        })

        return [contributionsAction, userGroupsAction, logsAction]
    }

    fileprivate var overflowSubmenuActions: [UIAction] {
        
        let goToArchivesAction = UIAction(title: "Archives", image: UIImage(systemName: "star"), handler: { _ in
            print("hi")
        })
        let pageInfoAction = UIAction(title: "Page information", image: UIImage(systemName: "star"), handler: { _ in
            print("hi")
        })
        
        let goToPermalinkAction = UIAction(title: "Permanent link", image: UIImage(systemName: "star"), handler: { _ in
            print("hi")
        })
        let changeLanguageAction = UIAction(title: "Change language", image: UIImage(systemName: "star"), handler: { _ in
            print("hi")
        })
        let getLinksAction = UIAction(title: "What links here", image: UIImage(systemName: "star"), handler: { _ in
            print("hi")
        })
        
        let aboutTalkPagesAction = UIAction(title: "About talk pages", image: UIImage(systemName: "star"), handler: { _ in
            print("hi")
        })
        
        var actions = [goToArchivesAction, pageInfoAction, goToPermalinkAction, changeLanguageAction, getLinksAction, aboutTalkPagesAction]
        
        if viewModel.pageType == .user {
            actions.insert(contentsOf: userTalkOverflowSubmenuActions, at: 1)
        }
        return actions
    }
    
    var overflowMenu: UIMenu {
        
        let openAllAction = UIAction(title: "Open all threads", image: UIImage(systemName: "star"), handler: { _ in
            print("hi")
        })
        let revisionHistoryAction = UIAction(title: "Rev history", image: UIImage(systemName: "star"), handler: { _ in
            print("hi")
        })
        let openInWebAction = UIAction(title: "Read in web", image: UIImage(systemName: "star"), handler: { _ in
            print("hi")
        })
        
        let submenu = UIMenu(title: String(), options: .displayInline, children: overflowSubmenuActions)
        let mainMenu = UIMenu(title: String(), image: nil,  children: [openAllAction, revisionHistoryAction, openInWebAction, submenu])

        return mainMenu
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

        // Not adding fallback for other versions since we're dropping iOS 13 on the next release
        // TODO this version check should be removed
        if #available(iOS 14.0, *) {
            let rightBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "ellipsis.circle"), primaryAction: nil, menu: overflowMenu)
            navigationItem.rightBarButtonItem = rightBarButtonItem
            rightBarButtonItem.tintColor = theme.colors.link
        }
       
        talkPageView.collectionView.dataSource = self
        talkPageView.collectionView.delegate = self
 
        // Needed for reply compose views to display on top of navigation bar.
        navigationController?.setNavigationBarHidden(true, animated: false)
        navigationMode = .forceBar

        viewModel.fetchTalkPage()
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

        cell.configure(viewModel: viewModel)
        cell.apply(theme: theme)
        cell.delegate = self

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
