import UIKit
import WMF
import WMFComponents
import WMFData
import WMFNativeLocalizations
import CocoaLumberjackSwift

final class DiscoverReadingListCoordinator: NSObject, Coordinator {

    let navigationController: UINavigationController
    private let dataStore: MWKDataStore
    private let theme: Theme
    private var settingsCoordinator: DiscoverSettingsCoordinator?
    private var createReadingListCoordinator: CreateReadingListCoordinator?
    private var shareReadingListCoordinator: ShareReadingListCoordinator?

    init(navigationController: UINavigationController, dataStore: MWKDataStore, theme: Theme) {
        self.navigationController = navigationController
        self.dataStore = dataStore
        self.theme = theme
        super.init()
    }

    // MARK: - Coordinator

    @discardableResult
    func start() -> Bool {
        let viewModel = WMFDiscoverReadingListViewModel(username: dataStore.authenticationManager.authStatePermanentUsername)

        viewModel.didTapArticle = { [weak self] page in
            self?.showArticle(page, inNewTab: false)
        }
        viewModel.didTapOpenInNewTab = { [weak self] page in
            WMFArticleTabsDataController.shared.didTapOpenNewTab()
            ArticleTabsFunnel.shared.logLongPressOpenInNewTab()
            self?.showArticle(page, inNewTab: true)
        }
        viewModel.didTapOpenInBackgroundTab = { [weak self] page in
            self?.openArticleInBackgroundTab(page)
        }
        viewModel.didTapShareArticle = { [weak self] page, sourceRect in
            self?.shareArticle(page, sourceRect: sourceRect)
        }
        viewModel.didTapSaveList = { [weak self] pages in
            self?.showSaveListSheet(for: pages)
        }
        viewModel.didTapShareList = { [weak self, weak viewModel] pages, sourceRect in
            guard let viewModel else { return }
            self?.shareList(pages, title: viewModel.title, sourceRect: sourceRect)
        }
        viewModel.didTapAbout = { [weak self] in
            self?.showAbout()
        }
        viewModel.didTapCustomize = { [weak self] in
            self?.showSettings()
        }

        let hostingController = WMFDiscoverReadingListHostingController(viewModel: viewModel)
        navigationController.pushViewController(hostingController, animated: true)
        return true
    }

    // MARK: - Articles

    private func showArticle(_ page: WMFDiscoverRecommendedPage, inNewTab: Bool) {
        guard let articleURL = page.articleURL else { return }
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

    private func openArticleInBackgroundTab(_ page: WMFDiscoverRecommendedPage) {
        guard let articleURL = page.articleURL else { return }

        Task {
            do {
                let articleTabsDataController = WMFArticleTabsDataController.shared
                articleTabsDataController.didTapOpenNewTab()

                let tabsCount = try await articleTabsDataController.tabsCount()
                let tabsMax = articleTabsDataController.tabsMax
                let article = WMFArticleTabsDataController.WMFArticle(identifier: nil, title: page.title, project: page.project, articleURL: articleURL)
                if tabsCount >= tabsMax {
                    if let currentTabIdentifier = try await articleTabsDataController.currentTabIdentifier() {
                        _ = try await articleTabsDataController.appendArticle(article, toTabIdentifier: currentTabIdentifier)
                    } else {
                        _ = try await articleTabsDataController.createArticleTab(initialArticle: article)
                    }
                    try await Task.sleep(for: .seconds(1))
                    WMFToastManager.sharedInstance.showRichToast(String.localizedStringWithFormat(CommonStrings.articleTabsLimitToastFormat, tabsMax), subtitle: nil, image: WMFSFSymbolIcon.for(symbol: .exclamationMarkTriangleFill), dismissPreviousToasts: true)
                } else {
                    _ = try await articleTabsDataController.createArticleTab(initialArticle: article, setAsCurrent: false)
                    ArticleTabsFunnel.shared.logLongPressOpenInBackgroundTab()
                }
            } catch {
                DDLogError("Failed to create background tab: \(error)")
            }
        }
    }

    // MARK: - Share

    private func shareArticle(_ page: WMFDiscoverRecommendedPage, sourceRect: CGRect) {
        guard let articleURL = page.articleURL,
              let article = dataStore.fetchOrCreateArticle(with: articleURL) else {
            return
        }

        let addToReadingListActivity = AddToReadingListActivity { [weak self] in
            self?.presentAddArticlesToReadingList(articles: [article])
        }
        let shareActivityController = ShareActivityController(article: article, customActivities: [addToReadingListActivity])
        present(shareActivityController, sourceRect: sourceRect)
    }

    private func shareList(_ pages: [WMFDiscoverRecommendedPage], title: String, sourceRect: CGRect) {
        let sharePages = pages.map { WMFShareReadingListDataController.Page(title: $0.title, project: $0.project) }
        let shareReadingListCoordinator = ShareReadingListCoordinator(
            navigationController: navigationController,
            pages: sharePages,
            listName: title,
            sourceRect: sourceRect
        )

        self.shareReadingListCoordinator = shareReadingListCoordinator
        shareReadingListCoordinator.start()
    }

    private func present(_ activityViewController: UIActivityViewController, sourceRect: CGRect) {
        if UIDevice.current.userInterfaceIdiom == .pad {
            activityViewController.popoverPresentationController?.sourceView = navigationController.view
            activityViewController.popoverPresentationController?.sourceRect = sourceRect
        }
        navigationController.present(activityViewController, animated: true)
    }

    // MARK: - Settings

    private func showSettings() {
        let coordinator = DiscoverSettingsCoordinator(navigationController: navigationController, dataStore: dataStore, theme: theme, origin: .discoverReadingList)
        settingsCoordinator = coordinator
        coordinator.start()
    }

    // MARK: - About

    /// Tentative page from the product manager. The page does not exist yet.
    private var aboutURL: URL? {
        guard let appLanguage = WMFDataEnvironment.current.primaryAppLanguage else { return nil }
        return WMFProject.mediawiki.translatedHelpURL(
            pathComponents: ["Wikimedia Apps", "Team", "Discover Reading List On iOS"],
            section: nil,
            language: appLanguage)
    }

    private func showAbout() {
        guard let url = aboutURL else { return }
        let config = SinglePageWebViewController.StandardConfig(url: url, useSimpleNavigationBar: true)
        let webViewController = SinglePageWebViewController(configType: .standard(config), theme: theme)
        let webNavigationController = WMFComponentNavigationController(rootViewController: webViewController, modalPresentationStyle: .fullScreen)
        navigationController.present(webNavigationController, animated: true)
    }

    // MARK: - Save

    private func showSaveListSheet(for pages: [WMFDiscoverRecommendedPage]) {
        let coordinator = CreateReadingListCoordinator(presentingViewController: navigationController, discoverPages: pages, dataStore: dataStore)
        coordinator.delegate = self
        coordinator.didDismiss = { [weak self] in
            self?.createReadingListCoordinator = nil
        }
        createReadingListCoordinator = coordinator
        coordinator.start()
    }

    /// The articles come from Discover with only a key. The summary fills the description and image the reading list rows show.
    private func updateSummaries(of articles: [WMFArticle]) {
        let keys = articles.compactMap(\.inMemoryKey)
        guard !keys.isEmpty else { return }
        dataStore.articleSummaryController.updateOrCreateArticleSummariesForArticles(withKeys: keys) { _, error in
            if let error {
                DDLogError("Failed to update summaries of the articles saved from Discover: \(error)")
            }
        }
    }

    /// Returns when the summaries are saved or the fetch fails. The list is saved in both cases.
    private func updateSummariesAndWait(of articles: [WMFArticle]) async {
        let keys = articles.compactMap(\.inMemoryKey)
        guard !keys.isEmpty else { return }
        await withCheckedContinuation { continuation in
            dataStore.articleSummaryController.updateOrCreateArticleSummariesForArticles(withKeys: keys) { _, error in
                if let error {
                    DDLogError("Failed to update summaries of the articles saved from Discover: \(error)")
                }
                continuation.resume()
            }
        }
    }

    /// Opens the new list the same way as an imported shared list.
    private func showReadingList(_ readingList: ReadingList) {
        if let appViewController = navigationController.tabBarController as? WMFAppViewController {
            appViewController.showReadingList(readingList, fromImport: false)
            return
        }
        navigationController.dismiss(animated: true) { [weak self] in
            guard let self else { return }
            let detailViewController = ReadingListDetailViewController(for: readingList, with: dataStore, fromImport: false, theme: theme)
            navigationController.pushViewController(detailViewController, animated: true)
        }
    }

    private func presentAddArticlesToReadingList(articles: [WMFArticle]) {
        let addArticlesToReadingListViewController = AddArticlesToReadingListViewController(with: dataStore, articles: articles, theme: theme)
        addArticlesToReadingListViewController.delegate = self
        let addArticlesNavigationController = WMFComponentNavigationController(rootViewController: addArticlesToReadingListViewController, modalPresentationStyle: .overFullScreen)
        navigationController.present(addArticlesNavigationController, animated: true)
    }
}

extension DiscoverReadingListCoordinator: AddArticlesToReadingListDelegate {
    func addArticlesToReadingListWillClose(_ addArticlesToReadingList: AddArticlesToReadingListViewController) {
        // no-op
    }

    func addArticlesToReadingListDidDisappear(_ addArticlesToReadingList: AddArticlesToReadingListViewController) {
        // no-op
    }

    func addArticlesToReadingList(_ addArticlesToReadingList: AddArticlesToReadingListViewController, didAddArticles articles: [WMFArticle], to readingList: WMF.ReadingList) {
        updateSummaries(of: articles)
    }
}

extension DiscoverReadingListCoordinator: CreateReadingListCoordinatorDelegate {
    func createReadingListCoordinator(
        _ coordinator: CreateReadingListCoordinator,
        didCreateReadingListWith name: String,
        description: String,
        articles: [WMFArticle]
    ) {
        guard !articles.isEmpty else { return }

        coordinator.setCreating(true)
        Task { @MainActor [weak self, weak coordinator] in
            // The list picks its preview images when it is created, so the articles need their summaries first.
            await self?.updateSummariesAndWait(of: articles)
            guard let self, let coordinator else { return }
            do {
                let readingList = try dataStore.readingListsController.createReadingList(named: name, description: description, with: articles)
                showReadingList(readingList)
            } catch let error as ReadingListError where error == .listExistsWithTheSameName {
                coordinator.handleReadingListNameError(error)
                coordinator.setCreating(false)
            } catch {
                WMFToastManager.sharedInstance.showErrorAlert(error, sticky: true, dismissPreviousToasts: true, tapCallBack: nil)
                coordinator.setCreating(false)
            }
        }
    }
}

extension WMFDiscoverRecommendedPage {
    var articleURL: URL? {
        guard let siteURL = project.siteURL,
              var articleURL = siteURL.wmf_URL(withTitle: title) else {
            return nil
        }
        articleURL.wmf_languageVariantCode = project.languageVariantCode
        return articleURL
    }
}
