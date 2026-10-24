import UIKit
import WMFComponents
import WMFData
import CocoaLumberjackSwift
import WMFNativeLocalizations

final class SavedAllArticlesCoordinator: NSObject, Coordinator {

    private let navigationControllerProvider: () -> UINavigationController
    var navigationController: UINavigationController {
        navigationControllerProvider()
    }
    private let dataStore: MWKDataStore
    var theme: Theme
    private var dataSource: LegacyReadingListsDataSource?
    private var _viewModel: WMFSavedAllArticlesViewModel?
    private var readingListsCoordinator: ReadingListsCoordinator?

    /// The Saved tab builds its segments before its navigation controller exists, so the
    /// navigation controller is resolved when first needed.
    init(navigationControllerProvider: @escaping () -> UINavigationController, dataStore: MWKDataStore, theme: Theme) {
        self.navigationControllerProvider = navigationControllerProvider
        self.dataStore = dataStore
        self.theme = theme
        super.init()
    }

    // MARK: - Coordinator

    func start() -> Bool {
        // The segment is embedded in the Saved tab. Use `viewModel`.
        return true
    }

    // MARK: - View model

    var viewModel: WMFSavedAllArticlesViewModel {
        if let _viewModel {
            return _viewModel
        }

        let dataSource = LegacyReadingListsDataSource(dataStore: dataStore)
        dataSource.unsaveConfirmation = { [weak self] articles, fromLongPress, completion in
            self?.deleteSavedArticles(articles: articles, fromLongPress: fromLongPress, completion: completion)
        }
        dataSource.savedArticleAlertDidChange = { [weak self] articleID, alertType in
            self?._viewModel?.updateAlertType(id: articleID, alertType: alertType)
        }
        let dataController = WMFLegacyReadingListsDataController(delegate: dataSource)
        self.dataSource = dataSource

        let viewModel = WMFSavedAllArticlesViewModel(dataController: dataController)
        viewModel.loggingDelegate = self

        viewModel.didTapArticle = { [weak self] article, _ in
            self?.showArticle(title: article.title, project: article.project, inNewTab: false)
        }

        viewModel.didTapOpenInNewTab = { [weak self] article in
            WMFArticleTabsDataController.shared.didTapOpenNewTab()
            self?.showArticle(title: article.title, project: article.project, inNewTab: true)
        }

        viewModel.didTapOpenInBackgroundTab = { [weak self] article in
            self?.openArticleInBackgroundTab(title: article.title, project: article.project)
        }

        viewModel.didTapShare = { [weak self] article, cgRect, _ in
            self?.shareArticle(article, cgRect: cgRect)
        }

        viewModel.didTapAddToList = { [weak self] articles in
            self?.showAddToListSheet(for: articles)
        }

        viewModel.didPullToRefresh = { [weak self] in
            guard let self else { return }

            await self.fullSync()
            await self.dataSource?.retryFailedArticleDownloads()

            await MainActor.run {
                self._viewModel?.loadArticles()
            }
        }

        viewModel.didTapArticleAlert = { [weak self] savedArticle in
            guard let self,
                  let article = self.articles(for: [savedArticle]).first else {
                return
            }
            presentArticleErrorRecovery(with: article)
        }

        viewModel.didTapReadingListTag = { [weak self] savedArticle, readingListName in
            guard let self else { return }

            if let name = readingListName,
               let readingList = dataSource.customReadingLists(forArticleID: savedArticle.id).first(where: { $0.name == name }) {
                let viewController = ReadingListDetailViewController(for: readingList, with: dataStore)
                viewController.apply(theme: theme)
                navigationController.pushViewController(viewController, animated: true)
            } else {
                let coordinator = ReadingListsCoordinator(navigationController: navigationController, dataStore: dataStore, theme: theme, filter: .named(savedArticle.readingListNames))
                self.readingListsCoordinator = coordinator
                _ = coordinator.start()
            }
        }

        _viewModel = viewModel
        return viewModel
    }

    // MARK: - Navigation

    private func showArticle(title: String, project: WMFProject, inNewTab: Bool) {

        guard let siteURL = project.siteURL,
              var articleURL = siteURL.wmf_URL(withTitle: title) else {
            return
        }
        articleURL.wmf_languageVariantCode = project.languageVariantCode

        let tabConfig: ArticleTabConfig = inNewTab ? .appendArticleAndAssignNewTabAndSetToCurrent : .appendArticleAndAssignCurrentTab

        let articleCoordinator = ArticleCoordinator(
            navigationController: navigationController,
            articleURL: articleURL,
            dataStore: dataStore,
            theme: theme,
            source: .undefined,
            tabConfig: tabConfig
        )
        articleCoordinator.start()
    }

    private func openArticleInBackgroundTab(title: String, project: WMFProject) {

        guard let siteURL = project.siteURL,
              var articleURL = siteURL.wmf_URL(withTitle: title) else {
            return
        }

        articleURL.wmf_languageVariantCode = project.languageVariantCode

        Task {
            do {
                let articleTabsDataController = WMFArticleTabsDataController.shared
                articleTabsDataController.didTapOpenNewTab()

                let tabsCount = try await articleTabsDataController.tabsCount()
                let tabsMax = articleTabsDataController.tabsMax
                let article = WMFArticleTabsDataController.WMFArticle(identifier: nil, title: title, project: project, articleURL: articleURL)
                if tabsCount >= tabsMax {

                    if let currentTabIdentifier = try await articleTabsDataController.currentTabIdentifier() {
                        _ = try await articleTabsDataController.appendArticle(article, toTabIdentifier: currentTabIdentifier)
                    } else {
                        _ = try await articleTabsDataController.createArticleTab(initialArticle: article)
                    }


                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        WMFToastManager.sharedInstance.showRichToast(String.localizedStringWithFormat(CommonStrings.articleTabsLimitToastFormat, tabsMax), subtitle: nil, image: WMFSFSymbolIcon.for(symbol: .exclamationMarkTriangleFill), dismissPreviousToasts: true)
                    }
                } else {
                    _ = try await articleTabsDataController.createArticleTab(initialArticle: article, setAsCurrent: false)
                    ArticleTabsFunnel.shared.logLongPressOpenInBackgroundTab()
                }

            } catch {
                DDLogError("Failed to create background tab: \(error)")
            }
        }

    }

    private func shareArticle(_ savedArticle: WMFSavedArticle, cgRect: CGRect) {

        guard let article = articles(for: [savedArticle]).first else {
            return
        }

        var customActivities: [UIActivity] = []
        let addToReadingListActivity = AddToReadingListActivity { [weak self] in
            guard let self else { return }
            let addArticlesToReadingListViewController = AddArticlesToReadingListViewController(with: dataStore, articles: [article], theme: theme)
            addArticlesToReadingListViewController.delegate = self
            let navVC = WMFComponentNavigationController(rootViewController: addArticlesToReadingListViewController, modalPresentationStyle: .overFullScreen)
            navigationController.present(navVC, animated: true, completion: nil)
        }
        customActivities.append(addToReadingListActivity)

        let shareActivityController = ShareActivityController(article: article, customActivities: customActivities)
        shareActivityController.popoverPresentationController?.sourceView = navigationController.view
        shareActivityController.popoverPresentationController?.sourceRect = cgRect
        navigationController.present(shareActivityController, animated: true, completion: nil)

    }

    private func articles(for savedArticles: [WMFSavedArticle]) -> [WMFArticle] {
        dataSource?.articles(withIDs: savedArticles.map { $0.id }) ?? []
    }

    private func showAddToListSheet(for savedArticles: [WMFSavedArticle]) {

        let articles = articles(for: savedArticles)

        let addArticlesToReadingListViewController = AddArticlesToReadingListViewController(with: dataStore, articles: articles, theme: theme)
        let navVC = WMFComponentNavigationController(rootViewController: addArticlesToReadingListViewController, modalPresentationStyle: .overFullScreen)
        addArticlesToReadingListViewController.delegate = self
        self.navigationController.present(navVC, animated: true)
    }

    private func presentArticleErrorRecovery(with article: WMFArticle) {
        switch article.error {
        case .apiFailed:
            let alert = UIAlertController(title: article.error.localizedDescription, message: nil, preferredStyle: .actionSheet)
            let retry = UIAlertAction(title: CommonStrings.retryActionTitle, style: .default) { _ in
                article.retryDownload()
            }
            alert.addAction(retry)
            let cancel = UIAlertAction(title: CommonStrings.cancelActionTitle, style: .default)
            alert.addAction(cancel)
            navigationController.present(alert, animated: true)
        default:
            break
        }
    }

    private func fullSync() async {
        await withCheckedContinuation { continuation in
            dataStore.readingListsController.fullSync {
                continuation.resume()
            }
        }
    }

}

// MARK: - Unsave with confirmation

extension SavedAllArticlesCoordinator {
    /// Transitional: the SwiftUI list asks before unsaving an article that is in a custom list.
    func deleteSavedArticles(articles: [WMFSavedArticle], fromLongPress: Bool, completion: @escaping (Bool) -> Void) {

        if fromLongPress {
            ArticleTabsFunnel.shared.logLongPressSave()
        }

        let wmfArticles = self.articles(for: articles)

        let alertController = ReadingListsAlertController()
        let unsave = ReadingListsAlertActionType.unsave.action { [weak self] in
            guard let self else { return }
            self.unsaveAndAnnounceAndLog(articles: wmfArticles)
            completion(true)
        }
        let cancel = ReadingListsAlertActionType.cancel.action {
            completion(false)
        }

        alertController.showAlertIfNeeded(presenter: self.navigationController, for: wmfArticles, with: [cancel, unsave]) { [weak self] showed in
            guard let self else { return }
            if !showed {
                self.unsaveAndAnnounceAndLog(articles: wmfArticles)
                completion(true)
            }
        }
    }

    private func unsaveAndAnnounceAndLog(articles: [WMFArticle]) {
        dataStore.readingListsController.unsave(articles, in: dataStore.viewContext)

        let articlesCount = articles.count
        UIAccessibility.post(notification: UIAccessibility.Notification.announcement, argument: CommonStrings.articleDeletedNotification(articleCount: articlesCount))
        let language = articles.count == 1 ? articles.first?.url?.wmf_languageCode : nil
        ReadingListsFunnel.shared.logUnsaveInReadingList(articlesCount: articlesCount, language: language)
    }
}

// MARK: - WMFSavedAllArticlesLoggingDelegate

extension SavedAllArticlesCoordinator: WMFSavedAllArticlesLoggingDelegate {
    func savedAllArticlesDidTapArticle(_ article: WMFSavedArticle, fromLongPress: Bool) {
        if let siteURL = article.project.siteURL, let articleURL = siteURL.wmf_URL(withTitle: article.title) {
            ReadingListsFunnel.shared.logReadStartReadingList(articleURL)
        }
        if fromLongPress {
            ArticleTabsFunnel.shared.logLongPressOpen()
        }
    }

    func savedAllArticlesDidTapOpenInNewTab() {
        ArticleTabsFunnel.shared.logLongPressOpenInNewTab()
    }

    func savedAllArticlesDidTapShare(fromLongPress: Bool) {
        if fromLongPress {
            ArticleTabsFunnel.shared.logLongPressShare()
        }
    }
}

extension SavedAllArticlesCoordinator: AddArticlesToReadingListDelegate {
    func addArticlesToReadingListWillClose(_ addArticlesToReadingList: AddArticlesToReadingListViewController) {
        // no-op
    }

    func addArticlesToReadingListDidDisappear(_ addArticlesToReadingList: AddArticlesToReadingListViewController) {
        // no-op
    }

    func addArticlesToReadingList(_ addArticlesToReadingList: AddArticlesToReadingListViewController, didAddArticles articles: [WMFArticle], to readingList: WMF.ReadingList) {
        _viewModel?.toggleEditing()
        _viewModel?.loadArticles()
    }
}
