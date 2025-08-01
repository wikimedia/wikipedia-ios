import UIKit
import SwiftUI
import WMFData
import WMFComponents
import WMF

final class WMFNewArticleTabViewController: WMFCanvasViewController, WMFNavigationBarConfiguring, Themeable {

    // MARK: - Properties

    private let hostingController: WMFNewArticleTabHostingController<WMFNewArticleTabView>
    private let dataStore: MWKDataStore
    private var theme: Theme
    private var presentingSearchResults: Bool = false
    private let viewModel: WMFNewArticleTabViewModel

    // MARK: - Navigation bar button properties

    private var yirDataController: WMFYearInReviewDataController? {
        return try? WMFYearInReviewDataController()
    }

    private var _yirCoordinator: YearInReviewCoordinator?
    var yirCoordinator: YearInReviewCoordinator? {

        guard let navigationController,
              let yirDataController else {
            return nil
        }

        guard let existingYirCoordinator = _yirCoordinator else {
            _yirCoordinator = YearInReviewCoordinator(navigationController: navigationController, theme: theme, dataStore: dataStore, dataController: yirDataController)
            _yirCoordinator?.badgeDelegate = self
            return _yirCoordinator
        }

        return existingYirCoordinator
    }

    private var _profileCoordinator: ProfileCoordinator?
    private var profileCoordinator: ProfileCoordinator? {

        guard let navigationController,
              let yirCoordinator = self.yirCoordinator else {
            return nil
        }

        guard let existingProfileCoordinator = _profileCoordinator else {
            _profileCoordinator = ProfileCoordinator(navigationController: navigationController, theme: theme, dataStore: dataStore, donateSouce: .savedProfile, logoutDelegate: self, sourcePage: ProfileCoordinatorSource.saved, yirCoordinator: yirCoordinator)
            _profileCoordinator?.badgeDelegate = self
            return _profileCoordinator
        }

        return existingProfileCoordinator
    }

    // MARK: - Lifecycle

    init(dataStore: MWKDataStore, theme: Theme, viewModel: WMFNewArticleTabViewModel) {
        self.dataStore = dataStore
        self.theme = theme
        self.viewModel = viewModel
        self.hostingController = WMFNewArticleTabHostingController(rootView: WMFNewArticleTabView())
        super.init()
        self.hidesBottomBarWhenPushed = true
        self.configureNavigationBar()
    }

    @MainActor required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    var showTabsOverview: (() -> Void)?

    public override func viewDidLoad() {
        super.viewDidLoad()
        addComponent(hostingController, pinToEdges: true)
        // Hack to solve coordinator retention issues
        showTabsOverview = { [weak navigationController, weak self] in
            guard let navController = navigationController, let self = self else { return }

            TabsCoordinatorManager.shared.presentTabsOverview(
                from: navController,
                theme: self.theme,
                dataStore: self.dataStore
            )
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        DispatchQueue.main.async { [weak self] in
            guard let searchController = self?.navigationItem.searchController else {
                return
            }

            searchController.isActive = true
            searchController.searchBar.becomeFirstResponder()
        }
    }

    // MARK: - Navigation bar configuring

    private func configureNavigationBar() {

        let wButton = UIButton(type: .custom)
        wButton.setImage(UIImage(named: "W"), for: .normal)

        let titleConfig: WMFNavigationBarTitleConfig = WMFNavigationBarTitleConfig(title: viewModel.title, customView: wButton, alignment: .centerCompact)

        let yirDataController = try? WMFYearInReviewDataController()
        let profileButtonConfig = profileButtonConfig(target: self, action: #selector(userDidTapProfile), dataStore: dataStore, yirDataController: yirDataController, leadingBarButtonItem: nil)

        let tabsButtonConfig = tabsButtonConfig(target: self, action: #selector(userDidTapTabs), dataStore: dataStore)

        let byrViewModel = self.viewModel.becauseYouReadViewModel != nil ? viewModel.becauseYouReadViewModel : nil
        let searchViewController = SearchViewController(source: .article, customArticleCoordinatorNavigationController: self.navigationController, needsAttachedView: true, becauseYouReadViewModel: byrViewModel)
        searchViewController.dataStore = dataStore
        searchViewController.theme = theme
        searchViewController.shouldBecomeFirstResponder = true
        searchViewController.customTabConfigUponArticleNavigation = .appendArticleAndAssignCurrentTabAndCleanoutFutureArticles

        let populateSearchBarWithTextAction: (String) -> Void = { [weak self] searchTerm in
            self?.navigationItem.searchController?.searchBar.text = searchTerm
            self?.navigationItem.searchController?.searchBar.becomeFirstResponder()
        }

        let navigateToSearchResultAction: ((URL) -> Void)? = { [weak self] url in

            guard let self else { return }
            if let navigationController {
                guard let title = url.wmf_title,
                      let siteURL = url.wmf_site,
                      let wmfProject = WikimediaProject(siteURL: siteURL)?.wmfProject else {
                    return
                }

                let articleCoord = ArticleCoordinator(navigationController: navigationController, articleURL: url, dataStore: self.dataStore, theme: self.theme, source: .undefined, tabConfig: .assignNewTabAndSetToCurrentFromNewTabSearch(title: title, project: wmfProject))
                articleCoord.start()

                // remove the new tab view controller from stack
                var vcs = navigationController.viewControllers
                guard vcs.count >= 2 else { return }
                vcs.remove(at: vcs.count - 2)

                navigationController.setViewControllers(vcs, animated: false)
            }

        }

        searchViewController.populateSearchBarWithTextAction = populateSearchBarWithTextAction
        searchViewController.navigateToSearchResultAction = navigateToSearchResultAction
        searchViewController.theme = theme

        let searchBarConfig = WMFNavigationBarSearchConfig(searchResultsController: searchViewController, searchControllerDelegate: self, searchResultsUpdater: self, searchBarDelegate: nil, searchBarPlaceholder: CommonStrings.searchBarPlaceholder, showsScopeBar: false, scopeButtonTitles: nil)

        let backButtonConfig = WMFNavigationBarBackButtonConfig(needsCustomTruncateBackButtonTitle: true)

        configureNavigationBar(titleConfig: titleConfig, backButtonConfig: backButtonConfig, closeButtonConfig: nil, profileButtonConfig: profileButtonConfig, tabsButtonConfig: tabsButtonConfig, searchBarConfig: searchBarConfig, hideNavigationBarOnScroll: true)
    }

    @objc func userDidTapProfile() {
        profileCoordinator?.start()
    }

    @objc func userDidTapTabs() {
        navigationController?.popViewController(animated: true)
        showTabsOverview?()
    }

    func updateProfileButton() {
        let config = self.profileButtonConfig(target: self, action: #selector(userDidTapProfile), dataStore: dataStore, yirDataController: yirDataController, leadingBarButtonItem: nil)
        updateNavigationBarProfileButton(needsBadge: config.needsBadge, needsBadgeLabel: CommonStrings.profileButtonBadgeTitle, noBadgeLabel: CommonStrings.profileButtonTitle)
    }

    // MARK: - Theme

    public func apply(theme: WMF.Theme) {
        guard viewIfLoaded != nil else {
            return
        }
        self.theme = theme
        profileCoordinator?.theme = theme
        updateProfileButton()
    }

}

// MARK: - Fileprivate classes

fileprivate final class WMFNewArticleTabHostingController<WMFNewArticleTabView: View>: WMFComponentHostingController<WMFNewArticleTabView> {

}

// MARK: - Extensions

extension WMFNewArticleTabViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        guard let text = searchController.searchBar.text else {
            return
        }

        guard let searchViewController = navigationItem.searchController?.searchResultsController as? SearchViewController else {
            return
        }

        if text.isEmpty {
            searchViewController.searchTerm = nil
            searchViewController.updateRecentlySearchedVisibility(searchText: nil)
        } else {
            searchViewController.searchTerm = text
            searchViewController.updateRecentlySearchedVisibility(searchText: text)
            searchViewController.search()
        }

    }
}

extension WMFNewArticleTabViewController: UISearchControllerDelegate {

    func willPresentSearchController(_ searchController: UISearchController) {
        presentingSearchResults = true
        navigationController?.hidesBarsOnSwipe = false
    }

    func didDismissSearchController(_ searchController: UISearchController) {
        presentingSearchResults = false
        navigationController?.hidesBarsOnSwipe = true
        userDidTapTabs()
    }
}

extension WMFNewArticleTabViewController: UISearchBarDelegate {
    public func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        navigationController?.popViewController(animated: true)
    }
}

extension WMFNewArticleTabViewController: YearInReviewBadgeDelegate {
    func updateYIRBadgeVisibility() {
        updateProfileButton()
    }
}

extension WMFNewArticleTabViewController: LogoutCoordinatorDelegate {
    func didTapLogout() {
        wmf_showKeepSavedArticlesOnDevicePanelIfNeeded(triggeredBy: .logout, theme: theme) {
            self.dataStore.authenticationManager.logout(initiatedBy: .user)
        }
    }

}
