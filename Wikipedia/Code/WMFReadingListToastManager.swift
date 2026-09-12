import UIKit
import WMFComponents
@preconcurrency import WMFData
import WMFNativeLocalizations

/// Shows the reading list toasts after the user saves an article.
///
/// The first toast asks the user to add the article to a reading list. After the
/// user adds it, a second toast confirms the list and opens it on tap.
@MainActor
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
        !WMFToastPresenter.shared.isToastVisible
    }

    /// Closes the toast with an animation.
    @objc func dismissToast() {
        WMFToastPresenter.shared.dismissCurrentToast()
    }

    /// Shows or closes the toast for the save state of the article.
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

        let articleURL = article.url

        let config = WMFToastConfig(
            title: toastButtonTitle(for: article),
            icon: WMFSFSymbolIcon.for(symbol: .plusCircle),
            iconStyle: .symbol,
            duration: Self.toastDuration,
            tapAction: { [weak self] in
                guard let self, let articleURL else { return }
                guard let article = self.dataStore.fetchArticle(with: articleURL) else { return }
                self.performDefaultAction(article: article)
            }
        )
        show(config, from: presenter)
    }

    private func showConfirmationToast(readingList: ReadingList, image: UIImage?) {
        guard let name = readingList.name,
              let presenter,
              presenter.view.window != nil else { return }

        let title = String.localizedStringWithFormat(
            WMFLocalizedString(
                "reading-lists-article-added-confirmation",
                value: "Article added to \"%1$@\"",
                comment: "Confirmation shown after the user adds an article to a list. %1$@ will be replaced with the name of the list the article was added to."
            ),
            name
        )

        let readingListObjectID = readingList.objectID
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
        show(config, from: presenter)
    }

    /// Shows the toast in the window of the presenter. Does nothing when the presenter shows a modal.
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

    /// Loads the thumbnail through the shared image cache. The article view has
    /// usually loaded the same image, so this call rarely goes to the network.
    private func loadThumbnail(from url: URL) async -> UIImage? {
        guard let data = try? await WMFImageDataController.shared.fetchImageData(url: url) else { return nil }
        return UIImage(data: data)
    }
}

// MARK: - AddArticlesToReadingListDelegate

// The delegate protocol is not isolated. The view controller calls it on the main
// actor, so the @preconcurrency conformance is safe.
extension WMFReadingListToastManager: @preconcurrency AddArticlesToReadingListDelegate {
    func addArticlesToReadingList(
        _ addArticlesToReadingList: AddArticlesToReadingListViewController,
        didAddArticles articles: [WMFArticle],
        to readingList: ReadingList
    ) {
        presenter?.dismiss(animated: true) { [weak self] in
            guard let self else { return }
            self.showConfirmationToast(readingList: readingList, image: nil)

            // Show the thumbnail when it loads.
            guard let imageURL = articles.first?.imageURL(forWidth: ImageUtils.nearbyThumbnailWidth()) else { return }

            Task { [weak self] in
                guard let self else { return }
                let image = await self.loadThumbnail(from: imageURL)
                self.showConfirmationToast(readingList: readingList, image: image)
            }
        }
    }

    func addArticlesToReadingListWillClose(_ addArticlesToReadingList: AddArticlesToReadingListViewController) {
        // No action. The confirmation toast is already on screen.
    }
}

// MARK: - Themeable

// Themeable is a legacy protocol without isolation. The app calls it on the main actor.
extension WMFReadingListToastManager: @preconcurrency Themeable {
    func apply(theme: Theme) {
        self.theme = theme
    }
}

// MARK: - Context Key

extension WMFReadingListToastManager {
    @objc public static let ContextArticleKey = "ContextArticleKey"
}
