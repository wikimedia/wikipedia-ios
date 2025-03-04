import UIKit
import WMF
import WMFComponents
import WMFData
import CocoaLumberjackSwift

@objc(WMFHistoryViewController)
class HistoryViewController: ArticleFetchedResultsViewController, WMFNavigationBarConfiguring, WMFNavigationBarHiding {
    
    var topSafeAreaOverlayHeightConstraint: NSLayoutConstraint?
    var topSafeAreaOverlayView: UIView?
    
    // Properties needed for Profile Button

   private var _yirCoordinator: YearInReviewCoordinator?
   var yirCoordinator: YearInReviewCoordinator? {

       guard let navigationController,
             let yirDataController,
             let dataStore else {
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
       let yirCoordinator = self.yirCoordinator,
           let dataStore else {
           return nil
       }

       guard let existingProfileCoordinator = _profileCoordinator else {
           _profileCoordinator = ProfileCoordinator(navigationController: navigationController, theme: theme, dataStore: dataStore, donateSouce: .historyProfile, logoutDelegate: self, sourcePage: ProfileCoordinatorSource.history, yirCoordinator: yirCoordinator)
           _profileCoordinator?.badgeDelegate = self
           return _profileCoordinator
       }

       return existingProfileCoordinator
   }

   private var yirDataController: WMFYearInReviewDataController? {
       return try? WMFYearInReviewDataController()
   }

    override var headerStyle: ColumnarCollectionViewController.HeaderStyle {
        return .sections
    }

    override func setupFetchedResultsController(with dataStore: MWKDataStore) {
        let articleRequest = WMFArticle.fetchRequest()
        articleRequest.predicate = NSPredicate(format: "viewedDate != NULL")
        articleRequest.sortDescriptors = [NSSortDescriptor(keyPath: \WMFArticle.viewedDateWithoutTime, ascending: false), NSSortDescriptor(keyPath: \WMFArticle.viewedDate, ascending: false)]
        fetchedResultsController = NSFetchedResultsController(fetchRequest: articleRequest, managedObjectContext: dataStore.viewContext, sectionNameKeyPath: "viewedDateWithoutTime", cacheName: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        emptyViewType = .noHistory
        
        title = CommonStrings.historyTabTitle
        
        deleteAllButtonText = WMFLocalizedString("history-clear-all", value: "Clear", comment: "Text of the button shown at the top of history which deletes all history {{Identical|Clear}}")
        deleteAllConfirmationText =  WMFLocalizedString("history-clear-confirmation-heading", value: "Are you sure you want to delete all your recent items?", comment: "Heading text of delete all confirmation dialog")
        deleteAllCancelText = WMFLocalizedString("history-clear-cancel", value: "Cancel", comment: "Button text for cancelling delete all action {{Identical|Cancel}}")
        deleteAllText = WMFLocalizedString("history-clear-delete-all", value: "Yes, delete all", comment: "Button text for confirming delete all action")
        
        setupTopSafeAreaOverlay(scrollView: collectionView)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        collectionViewUpdater.isGranularUpdatingEnabled = true
        
        configureNavigationBar()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        NSUserActivity.wmf_makeActive(NSUserActivity.wmf_recentView())
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        collectionViewUpdater.isGranularUpdatingEnabled = false
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        if #available(iOS 18, *) {
            if UIDevice.current.userInterfaceIdiom == .pad {
                if previousTraitCollection?.horizontalSizeClass != traitCollection.horizontalSizeClass {
                    configureNavigationBar()
                }
            }
        }
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: any UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        coordinator.animate(alongsideTransition: nil) { [weak self] _ in
            self?.calculateTopSafeAreaOverlayHeight()
        }
    }
    
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        super.scrollViewDidScroll(scrollView)
        calculateNavigationBarHiddenState(scrollView: scrollView)
    }
    
    override func deleteAll() {
        do {
            try dataStore.viewContext.clearReadHistory()
        } catch let error {
            showError(error)
        }
        
        Task {
            do {
                let dataController = try WMFPageViewsDataController()
                try await dataController.deleteAllPageViews()

            } catch {
                DDLogError("Failure deleting WMFData WMFPageViews: \(error)")
            }
        }
    }
    
    override func delete(at indexPath: IndexPath) {
        
        guard let article = article(at: indexPath) else {
            return
        }
        
        super.delete(at: indexPath)

        // Also delete from WMFData WMFPageViews
        guard let title = article.url?.wmf_title,
              let languageCode = article.url?.wmf_languageCode else {
            return
        }
        
        let variant = article.variant
        
        let project = WMFProject.wikipedia(WMFLanguage(languageCode: languageCode, languageVariantCode: variant))
        
        Task {
            do {
                let dataController = try WMFPageViewsDataController()
                try await dataController.deletePageView(title: title, namespaceID: 0, project: project)
            } catch {
                DDLogError("Failure deleting WMFData WMFPageViews: \(error)")
            }
        }
    }

    private func configureNavigationBar() {
        
        var titleConfig: WMFNavigationBarTitleConfig = WMFNavigationBarTitleConfig(title: CommonStrings.historyTabTitle, customView: nil, alignment: .leadingCompact)
        extendedLayoutIncludesOpaqueBars = false
        if #available(iOS 18, *) {
            if UIDevice.current.userInterfaceIdiom == .pad && traitCollection.horizontalSizeClass == .regular {
                titleConfig = WMFNavigationBarTitleConfig(title: CommonStrings.historyTabTitle, customView: nil, alignment: .leadingLarge)
                extendedLayoutIncludesOpaqueBars = true
            }
        }
        
        let hideNavigationBarOnScroll = !isEmpty
        
        let deleteButton = UIBarButtonItem(title: deleteAllButtonText, style: .plain, target: self, action: #selector(deleteButtonPressed(_:)))
        deleteButton.isEnabled = !isEmpty
        
        let profileButtonConfig: WMFNavigationBarProfileButtonConfig?
        if let dataStore {
            profileButtonConfig = self.profileButtonConfig(target: self, action: #selector(userDidTapProfile), dataStore: dataStore, yirDataController: yirDataController, leadingBarButtonItem: deleteButton, trailingBarButtonItem: nil)
        } else {
            profileButtonConfig = nil
        }

        configureNavigationBar(titleConfig: titleConfig, closeButtonConfig: nil, profileButtonConfig: profileButtonConfig, searchBarConfig: nil, hideNavigationBarOnScroll: hideNavigationBarOnScroll)
    }
    
    private func updateProfileButton() {

        guard let dataStore else {
            return
        }

        let config = self.profileButtonConfig(target: self, action: #selector(userDidTapProfile), dataStore: dataStore, yirDataController: yirDataController, leadingBarButtonItem: nil, trailingBarButtonItem: nil)
        updateNavigationBarProfileButton(needsBadge: config.needsBadge, needsBadgeLabel: CommonStrings.profileButtonBadgeTitle, noBadgeLabel: CommonStrings.profileButtonTitle)
    }

    @objc func userDidTapProfile() {
        
        guard let dataStore else {
            return
        }
        
        guard let languageCode = dataStore.languageLinkController.appLanguage?.languageCode,
              let metricsID = DonateCoordinator.metricsID(for: .historyProfile, languageCode: languageCode) else {
            return
        }
        
        DonateFunnel.shared.logHistoryProfile(metricsID: metricsID)
        
        profileCoordinator?.start()
    }

    func titleForHeaderInSection(_ section: Int) -> String? {
        guard let sections = fetchedResultsController.sections, sections.count > section else {
            return nil
        }
        let sectionInfo = sections[section]
        guard let article = sectionInfo.objects?.first as? WMFArticle, let date = article.viewedDateWithoutTime else {
            return nil
        }
        
        return ((date as NSDate).wmf_midnightUTCDateFromLocal as NSDate).wmf_localizedRelativeDateFromMidnightUTCDate()
    }
    
    override func configure(header: CollectionViewHeader, forSectionAt sectionIndex: Int, layoutOnly: Bool) {
        header.style = .history
        header.title = titleForHeaderInSection(sectionIndex)
        header.apply(theme: theme)
        header.layoutMargins = layout.itemLayoutMargins
    }
    
    override func collectionViewUpdater<T>(_ updater: CollectionViewUpdater<T>, didUpdate collectionView: UICollectionView) {
        super.collectionViewUpdater(updater, didUpdate: collectionView)
        updateVisibleHeaders()
        
        // if it switched to empty state, this line will disable hide nav bar on scroll
        configureNavigationBar()
    }

    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let navigationController,
              let articleURL = articleURL(at: indexPath) else {
            collectionView.deselectItem(at: indexPath, animated: true)
            return
        }
        
        let articleCoordinator = ArticleCoordinator(navigationController: navigationController, articleURL: articleURL, dataStore: dataStore, theme: theme, source: .history)
        articleCoordinator.start()
    }

    func updateVisibleHeaders() {
        for indexPath in collectionView.indexPathsForVisibleSupplementaryElements(ofKind: UICollectionView.elementKindSectionHeader) {
            guard let headerView = collectionView.supplementaryView(forElementKind: UICollectionView.elementKindSectionHeader, at: indexPath) as? CollectionViewHeader else {
                continue
            }
            headerView.title = titleForHeaderInSection(indexPath.section)
        }
    }
    
    override var eventLoggingCategory: EventCategoryMEP {
        return .history
    }
    
    override func apply(theme: Theme) {
        super.apply(theme: theme)
        
        updateProfileButton()
        profileCoordinator?.theme = theme
        
        themeTopSafeAreaOverlay()
    }
}

extension HistoryViewController: LogoutCoordinatorDelegate {
    func didTapLogout() {

        guard let dataStore else {
            return
        }

        wmf_showKeepSavedArticlesOnDevicePanelIfNeeded(triggeredBy: .logout, theme: theme) {
            dataStore.authenticationManager.logout(initiatedBy: .user)
        }
    }
}

extension HistoryViewController: YearInReviewBadgeDelegate {
    func updateYIRBadgeVisibility() {
        updateProfileButton()
    }
}
