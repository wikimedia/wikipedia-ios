import UIKit
import WMFComponents
@preconcurrency import WMFData
import WMFNativeLocalizations

@objc final class WMFReadingListToastManager: NSObject {

    // MARK: - Properties

    private let dataStore: MWKDataStore
    private weak var presenter: UIViewController?

    private var currentArticle: WMFArticle?
    private weak var themeableNavigationController: WMFComponentNavigationController?

    var theme = Theme.standard

    /// The time in seconds a reading list toast stays on screen.
    private static let toastDuration: TimeInterval = 13

    // MARK: - Init

    @objc init(dataStore: MWKDataStore) {
        self.dataStore = dataStore
        super.init()
    }

    // MARK: - Public Methods

    var isToastHidden: Bool {
        MainActor.assumeIsolated { !WMFToastPresenter.shared.isToastVisible }
    }

    /// Dismisses toast with animation - use for normal dismissals
    @objc func dismissToast() {
        Task { @MainActor in
            WMFToastPresenter.shared.dismissCurrentToast()
        }
    }

    /// Dismisses toast immediately without animation - use when keyboard is about to appear to prevent freezing
    @MainActor
    func dismissToastImmediately() {
        WMFToastPresenter.shared.dismissCurrentToast()
    }

    @objc func toggle(presenter: UIViewController, article: WMFArticle, theme: Theme) {
        self.presenter = presenter
        self.theme = theme

        let didSave = article.isSaved
        let didSaveOtherArticle = didSave && !isToastHidden && article != currentArticle
        let didUnsaveOtherArticle = !didSave && !isToastHidden && article != currentArticle

        guard !didUnsaveOtherArticle else { return }

        if didSaveOtherArticle {
            currentArticle = article
            showDefaultToast(article: article)
            return
        }

        currentArticle = article

        if didSave {
            showDefaultToast(article: article)
        } else {
            dismissToast()
        }
    }

    // MARK: - Private Methods

    private func showDefaultToast(article: WMFArticle) {
        guard let presenter else { return }

        let title = toastButtonTitle(for: article)
        let articleURL = article.url

        Task { @MainActor [weak self] in
            guard let self else { return }
            let config = WMFToastConfig(
                title: title,
                icon: WMFSFSymbolIcon.for(symbol: .plusCircle),
                iconStyle: .symbol,
                duration: Self.toastDuration,
                tapAction: { [weak self] in
                    guard let self, let articleURL else { return }
                    guard let article = self.dataStore.fetchArticle(with: articleURL) else { return }
                    self.performDefaultAction(article: article)
                }
            )
            self.show(config, from: presenter)
        }
    }

    private func showConfirmationToast(readingList: ReadingList, image: UIImage?) {
        guard let name = readingList.name else { return }

        let title = String.localizedStringWithFormat(
            WMFLocalizedString(
                "reading-lists-article-added-confirmation",
                value: "Article added to \"%1$@\"",
                comment: "Confirmation shown after the user adds an article to a list. %1$@ will be replaced with the name of the list the article was added to."
            ),
            name
        )

        let readingListObjectID = readingList.objectID

        Task { @MainActor [weak self] in
            guard let self, let presenter = self.presenter, presenter.view.window != nil else { return }

            let openReadingList: () -> Void = { [weak self] in
                guard let self,
                      let readingList = try? self.dataStore.viewContext.existingObject(with: readingListObjectID) as? ReadingList else { return }
                self.performConfirmationAction(readingList: readingList)
            }

            let config = WMFToastConfig(
                title: title,
                icon: image,
                iconStyle: .thumbnail,
                duration: Self.toastDuration,
                buttonTitle: WMFLocalizedString("reading-list-alert-see-list", value: "See reading list", comment: "Title for button on alert to see the reading list after adding an article to it."),
                tapAction: openReadingList,
                buttonAction: openReadingList
            )
            self.show(config, from: presenter)
        }
    }

    /// Shows the toast in the window of the presenter. Does nothing when the presenter shows a modal.
    @MainActor
    private func show(_ config: WMFToastConfig, from presenter: UIViewController) {
        guard presenter.presentedViewController == nil else { return }
        WMFToastPresenter.shared.show(config, in: presenter.view.window)
    }

    private func toastButtonTitle(for article: WMFArticle) -> String {
        var maybeArticleTitle: String?
        if let displayTitle = article.displayTitle, displayTitle.wmf_hasNonWhitespaceText {
            maybeArticleTitle = displayTitle
        } else if let articleURL = article.url, let title = articleURL.wmf_title {
            maybeArticleTitle = title
        }

        guard let articleTitle = maybeArticleTitle, articleTitle.wmf_hasNonWhitespaceText else {
            return WMFLocalizedString(
                "reading-list-add-generic-hint-title",
                value: "Add this article to a reading list?",
                comment: "Title of the reading list hint that appears after an article is saved."
            )
        }

        return String.localizedStringWithFormat(
            WMFLocalizedString(
                "reading-list-add-hint-title",
                value: "Add \"%1$@\" to a reading list?",
                comment: "Title of the reading list hint that appears after an article is saved. %1$@ will be replaced with the saved article title"
            ),
            articleTitle
        )
    }

    @MainActor
    private func performDefaultAction(article: WMFArticle) {
        guard let presenter else { return }
        WMFToastPresenter.shared.dismissCurrentToast()

        let addVC = AddArticlesToReadingListViewController(
            with: dataStore,
            articles: [article],
            moveFromReadingList: nil,
            theme: theme
        )
        addVC.delegate = self
        addVC.needsAutoDismissUponAdd = false

        let nav = WMFComponentNavigationController(
            rootViewController: addVC,
            modalPresentationStyle: .overFullScreen
        )

        presenter.present(nav, animated: true)
    }

    @MainActor
    private func performConfirmationAction(readingList: ReadingList) {
        guard let presenter else { return }
        WMFToastPresenter.shared.dismissCurrentToast()

        let detailVC = ReadingListDetailViewController(
            for: readingList,
            with: dataStore,
            displayType: .modal
        )
        detailVC.apply(theme: theme)

        let nav = WMFComponentNavigationController(
            rootViewController: detailVC,
            modalPresentationStyle: .overFullScreen
        )

        themeableNavigationController = nav

        presenter.present(nav, animated: true)
    }

    private func loadImageOffMain(from url: URL) async -> UIImage? {

        if url.isFileURL {
            return await Task(priority: .userInitiated) {
                guard let data = try? Data(contentsOf: url) else { return nil }
                return UIImage(data: data)
            }.value
        } else {
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                return UIImage(data: data)
            } catch {
                return nil
            }
        }
    }
}

// MARK: - AddArticlesToReadingListDelegate

extension WMFReadingListToastManager: AddArticlesToReadingListDelegate {
    func addArticlesToReadingList(
        _ addArticlesToReadingList: AddArticlesToReadingListViewController,
        didAddArticles articles: [WMFArticle],
        to readingList: ReadingList
    ) {
        presenter?.dismiss(animated: true) { [weak self] in
            guard let self else { return }
            self.showConfirmationToast(readingList: readingList, image: nil)

            // try loading thumbnail, update if successful
            let imageURL = articles.first?.imageURL(forWidth: ImageUtils.nearbyThumbnailWidth())
            guard let imageURL else { return }

            Task { [weak self] in
                guard let self else { return }
                let image = await self.loadImageOffMain(from: imageURL)
                await MainActor.run {
                    self.showConfirmationToast(readingList: readingList, image: image)
                }
            }
        }
    }

    func addArticlesToReadingListWillClose(_ addArticlesToReadingList: AddArticlesToReadingListViewController) {
        // No-op: confirmation state already applied in-place.
    }
}

// MARK: - Themeable

extension WMFReadingListToastManager: Themeable {
    func apply(theme: Theme) {
        self.theme = theme
    }
}

// MARK: - Context Key

extension WMFReadingListToastManager {
    @objc public static let ContextArticleKey = "ContextArticleKey"
}
