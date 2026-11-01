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
            self?.showAddToListSheet(for: pages)
        }
        viewModel.didTapShareList = { [weak self] pages, sourceRect in
            self?.shareList(pages, sourceRect: sourceRect)
        }
        viewModel.didTapAbout = { [weak self] in
            self?.showAbout()
        }

        let hostingController = WMFDiscoverReadingListHostingController(viewModel: viewModel)
        navigationController.pushViewController(hostingController, animated: true)
        return true
    }

    // MARK: - Articles

    private func articleURL(for page: WMFDiscoverRecommendedPage) -> URL? {
        guard let siteURL = page.project.siteURL,
              var articleURL = siteURL.wmf_URL(withTitle: page.title) else {
            return nil
        }
        articleURL.wmf_languageVariantCode = page.project.languageVariantCode
        return articleURL
    }

    private func showArticle(_ page: WMFDiscoverRecommendedPage, inNewTab: Bool) {
        guard let articleURL = articleURL(for: page) else { return }
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
        guard let articleURL = articleURL(for: page) else { return }

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
        guard let articleURL = articleURL(for: page),
              let article = dataStore.fetchOrCreateArticle(with: articleURL) else {
            return
        }

        let addToReadingListActivity = AddToReadingListActivity { [weak self] in
            self?.presentAddArticlesToReadingList(articles: [article])
        }
        let shareActivityController = ShareActivityController(article: article, customActivities: [addToReadingListActivity])
        present(shareActivityController, sourceRect: sourceRect)
    }

    private func shareList(_ pages: [WMFDiscoverRecommendedPage], sourceRect: CGRect) {
        let urls = pages.compactMap(articleURL(for:))
        guard !urls.isEmpty else { return }
        let activityViewController = UIActivityViewController(activityItems: urls, applicationActivities: nil)
        present(activityViewController, sourceRect: sourceRect)
    }

    private func present(_ activityViewController: UIActivityViewController, sourceRect: CGRect) {
        if UIDevice.current.userInterfaceIdiom == .pad {
            activityViewController.popoverPresentationController?.sourceView = navigationController.view
            activityViewController.popoverPresentationController?.sourceRect = sourceRect
        }
        navigationController.present(activityViewController, animated: true)
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

    private func showAddToListSheet(for pages: [WMFDiscoverRecommendedPage]) {
        let articles = pages.compactMap { page -> WMFArticle? in
            guard let articleURL = articleURL(for: page) else { return nil }
            return dataStore.fetchOrCreateArticle(with: articleURL)
        }
        guard !articles.isEmpty else { return }
        presentAddArticlesToReadingList(articles: articles)
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

    /// The articles come from Discover with only a key. The summary fills the description and image the reading list rows show.
    func addArticlesToReadingList(_ addArticlesToReadingList: AddArticlesToReadingListViewController, didAddArticles articles: [WMFArticle], to readingList: WMF.ReadingList) {
        let keys = articles.compactMap(\.inMemoryKey)
        guard !keys.isEmpty else { return }
        dataStore.articleSummaryController.updateOrCreateArticleSummariesForArticles(withKeys: keys) { _, error in
            if let error {
                DDLogError("Failed to update summaries of the articles saved from Discover: \(error)")
            }
        }
    }
}
