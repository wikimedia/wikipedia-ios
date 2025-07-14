import UIKit
import SwiftUI
import WMFData

final public class WMFNewArticleTabController: WMFCanvasViewController, WMFNavigationBarConfiguring {

    // move all this to view model, add loc strings

    private let hostingController: WMFNewArticleTabHostingController
    let viewModel: WMFNewArticleTabViewModel

    public init(viewModel: WMFNewArticleTabViewModel) {
        self.viewModel = viewModel
        self.hostingController = WMFNewArticleTabHostingController(rootView: WMFNewArticleTabView())
        super.init()
    }
    
    @MainActor required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewDidLoad() {
        super.viewDidLoad()

        addComponent(hostingController, pinToEdges: true)
    }

    private func configureNavigationBar() {

        let wButton = UIButton(type: .custom)
        wButton.setImage(UIImage(named: "W"), for: .normal)

        var titleConfig: WMFNavigationBarTitleConfig = WMFNavigationBarTitleConfig(title: "test??", customView: wButton, alignment: .centerCompact)

        if #available(iOS 18, *) {
            if UIDevice.current.userInterfaceIdiom == .pad && traitCollection.horizontalSizeClass == .regular { // ipad
                titleConfig = WMFNavigationBarTitleConfig(title: "test??", customView: nil, alignment: .hidden)
            }
        }

        let yirDataController = try? WMFYearInReviewDataController()
        let tabsButtonConfig = tabsButtonConfig(target: self, action: #selector(userDidTapTabs), accessibilityLabel: viewModel.localizedStrings.tabsButtonAccessibilityLabel, accessibilityHint: viewModel.localizedStrings.tabsButtonAccessibilityHint)

        let config = profileButtonConfig(target: self, action: #selector(userDidTapProfile), authStateTemp: viewModel.authStateTemp, authStatePermanent: viewModel.authStatePermanent, languageCode: viewModel.languageCode, languageVariantCode: viewModel.languageVariantCode, numberOfNotifications: viewModel.numberOfNotifications, accessibilityHint: viewModel.localizedStrings.profileButtionAccessibilityHint, accessibilityLabelNoNotifications: viewModel.localizedStrings.profileAccessibilityLabelNoNotifications, accessibilityLabelHasNotifications: viewModel.localizedStrings.profileAccessibilityLabelHasNotifications, yirDataController: yirDataController, leadingBarButtonItem: nil)

//
//
//        let searchViewController = SearchViewController(source: .article, customArticleCoordinatorNavigationController: navigationController)
//        searchViewController.dataStore = dataStore
//        searchViewController.theme = theme
//        searchViewController.shouldBecomeFirstResponder = true
//        searchViewController.customTabConfigUponArticleNavigation = .appendArticleAndAssignCurrentTabAndCleanoutFutureArticles
//
//        let populateSearchBarWithTextAction: (String) -> Void = { [weak self] searchTerm in
//            self?.navigationItem.searchController?.searchBar.text = searchTerm
//            self?.navigationItem.searchController?.searchBar.becomeFirstResponder()
//        }
//
//        searchViewController.populateSearchBarWithTextAction = populateSearchBarWithTextAction
//
//        let searchBarConfig = WMFNavigationBarSearchConfig(searchResultsController: searchViewController, searchControllerDelegate: self, searchResultsUpdater: self, searchBarDelegate: nil, searchBarPlaceholder: WMFLocalizedString("search-field-placeholder-text", value: "Search Wikipedia", comment: "Search field placeholder text"), showsScopeBar: false, scopeButtonTitles: nil)
//
//        configureNavigationBar(titleConfig: titleConfig, backButtonConfig: backButtonConfig, closeButtonConfig: nil, profileButtonConfig: profileButtonConfig, tabsButtonConfig: tabsButtonConfig, searchBarConfig: searchBarConfig, hideNavigationBarOnScroll: true)
    }

    @objc func userDidTapProfile() {

    }

    @objc func userDidTapTabs() {

    }

    // move to an extension in this package

    func tabsButtonConfig(target: Any, action: Selector, leadingBarButtonItem: UIBarButtonItem? = nil, trailingBarButtonItem: UIBarButtonItem? = nil, accessibilityLabel: String, accessibilityHint: String) -> WMFNavigationBarTabsButtonConfig {
        return WMFNavigationBarTabsButtonConfig(accessibilityLabel: accessibilityLabel, accessibilityHint: accessibilityHint, target: target, action: action, leadingBarButtonItem: leadingBarButtonItem, trailingBarButtonItem: trailingBarButtonItem)
    }

    func profileButtonConfig(target: Any, action: Selector, authStateTemp: Bool, authStatePermanent: Bool, languageCode: String, languageVariantCode: String?, numberOfNotifications: NSNumber?, accessibilityHint: String, accessibilityLabelNoNotifications: String, accessibilityLabelHasNotifications: String, yirDataController: WMFYearInReviewDataController?, leadingBarButtonItem: UIBarButtonItem?) -> WMFNavigationBarProfileButtonConfig {
        var hasUnreadNotifications: Bool = false

        let isTemporaryAccount = WMFTempAccountDataController.shared.primaryWikiHasTempAccountsEnabled && authStateTemp

        if authStateTemp || isTemporaryAccount {
            hasUnreadNotifications = (numberOfNotifications?.intValue ?? 0) != 0
        } else {
            hasUnreadNotifications = false
        }

        var needsYiRNotification = false
        if let yirDataController {
            let project = WMFProject.wikipedia(WMFLanguage(languageCode: languageCode, languageVariantCode: languageVariantCode))
            needsYiRNotification = yirDataController.shouldShowYiRNotification(primaryAppLanguageProject: project, isLoggedOut: !authStatePermanent, isTemporaryAccount: isTemporaryAccount)
        }
        // do not override `hasUnreadNotifications` completely
        if needsYiRNotification {
            hasUnreadNotifications = true
        }

        return WMFNavigationBarProfileButtonConfig(accessibilityLabelNoNotifications: accessibilityLabelNoNotifications, accessibilityLabelHasNotifications: accessibilityLabelHasNotifications, accessibilityHint: accessibilityHint, needsBadge: hasUnreadNotifications, target: target, action: action, leadingBarButtonItem: leadingBarButtonItem)
    }

}

fileprivate final class WMFNewArticleTabHostingController: WMFComponentHostingController<WMFNewArticleTabView> {

}
