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
        let contributionsAction = UIAction(title: MenuLocalizedStrings.contributions, image: UIImage(systemName: "star"), handler: { _ in
        })

        let userGroupsAction = UIAction(title: MenuLocalizedStrings.userGroups, image: UIImage(systemName: "person.2"), handler: { _ in
        })

        let logsAction = UIAction(title: MenuLocalizedStrings.logs, image: UIImage(systemName: "list.bullet"), handler: { _ in
        })

        return [contributionsAction, userGroupsAction, logsAction]
    }

    fileprivate var overflowSubmenuActions: [UIAction] {
        
        let goToArchivesAction = UIAction(title: MenuLocalizedStrings.archives, image: UIImage(systemName: "archivebox"), handler: { _ in
        })
        
        let pageInfoAction = UIAction(title: MenuLocalizedStrings.pageInfo, image: UIImage(systemName: "info.circle"), handler: { _ in
        })
        
        let goToPermalinkAction = UIAction(title: MenuLocalizedStrings.permaLink, image: UIImage(systemName: "link"), handler: { _ in
        })
        
        let relatedLinksAction = UIAction(title: MenuLocalizedStrings.relatedLinks, image: UIImage(systemName: "arrowshape.turn.up.forward"), handler: { _ in
        })
        
        var actions = [goToArchivesAction, pageInfoAction, goToPermalinkAction, relatedLinksAction]
        
        if viewModel.pageType == .user {
            let aboutTalkUserPagesAction = UIAction(title: MenuLocalizedStrings.aboutUserTalk, image: UIImage(systemName: "doc.plaintext"), handler: { _ in
                
            })
            actions.insert(contentsOf: userTalkOverflowSubmenuActions, at: 1)
            actions.append(aboutTalkUserPagesAction)
        } else {
            let changeLanguageAction = UIAction(title: MenuLocalizedStrings.changeLanguage, image: UIImage(named: "language"), handler: { _ in
            })
            let aboutTalkPagesAction = UIAction(title: MenuLocalizedStrings.aboutArticleTalk, image: UIImage(systemName: "doc.plaintext"), handler: { _ in
                
            })
            actions.insert(changeLanguageAction, at: 3)
            actions.append(aboutTalkPagesAction)
        }
        return actions
    }
    
    var overflowMenu: UIMenu {
        
        let openAllAction = UIAction(title: MenuLocalizedStrings.openAllThreads, image: UIImage(systemName: "square.stack"), handler: { _ in
           
        })
        
        let revisionHistoryAction = UIAction(title: MenuLocalizedStrings.revisionHistory, image: UIImage(systemName: "clock.arrow.circlepath"), handler: { _ in
            
        })
        
        let openInWebAction = UIAction(title: MenuLocalizedStrings.readInWeb, image: UIImage(systemName: "display"), handler: { _ in
            
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

extension TalkPageViewController {
    enum MenuLocalizedStrings {
        static let openAllThreads = WMFLocalizedString("talk-page-menu-open-all", value: "Open all threads", comment: "Title for menu option open all talk page threads")
        static let revisionHistory = WMFLocalizedString("talk-page-revision-history", value: "Revision history", comment: "Title for menu option that leads to talk pages revision history")
        static let readInWeb = WMFLocalizedString("talk-page-open-in-web", value: "Open in web", comment: "Title for menu option to open a talk page in a web browser")
        static let archives = WMFLocalizedString("talk-page-archives", value: "Archives", comment: "Title for menu option that redirects to talk page archives")
        static let pageInfo = WMFLocalizedString("talk-page-page-info", value: "Page information", comment: "Title for menu option to go to the talk page information link")
        static let permaLink = WMFLocalizedString("talk-page-permanent-link", value: "Permanent link", comment: "Title for menu option to open the talk page's permanent link in a web browser")
        static let changeLanguage = WMFLocalizedString("talk-page-change-language", value: "Change language", comment: "Title for menu option to got to the change language page")
        static let relatedLinks = WMFLocalizedString("talk-page-related-links", value: "What links here", comment: "Title for menu option that redirects to a page that shows related links")
        static let aboutArticleTalk = WMFLocalizedString("talk-page-article-about", value: "About talk pages", comment: "Title for menu option for information on article talk pages")
        static let aboutUserTalk = WMFLocalizedString("talk-page-user-about", value: "About user talk page", comment: "Title for menu option for information on article talk pages")
        static let contributions = WMFLocalizedString("talk-page-user-contributions", value: "Contributions", comment: "Title for menu option for information on the user's contributions")
        static let userGroups = WMFLocalizedString("talk-pages-user-groups", value: "User groups", comment: "Title for menu option for information on the user's user groups")
        static let logs = WMFLocalizedString("talk-pages-user-logs", value: "Logs", comment: "Title for menu option to consult the user's public logs")
    }
}
