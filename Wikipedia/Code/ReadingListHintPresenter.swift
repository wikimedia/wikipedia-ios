import UIKit
import WMFComponents
@preconcurrency import WMFData

// TODO: Rename hint to something that makes more sense, it's just a reading list helper now
@objc(WMFReadingListHintPresenter)
final class ReadingListHintPresenter: NSObject {

    // MARK: - Properties

    private let dataStore: MWKDataStore
    private var hintPresenter: WMFHintPresenter?
    private weak var presenter: UIViewController?

    private var currentArticle: WMFArticle?
    private weak var themeableNavigationController: WMFComponentNavigationController?

    var theme = Theme.standard

    // MARK: - Init

    @objc init(dataStore: MWKDataStore) {
        self.dataStore = dataStore
        super.init()
    }

    @MainActor
    private func getHintPresenter() -> WMFHintPresenter {
        if hintPresenter == nil {
            hintPresenter = WMFHintPresenter()
        }
        return hintPresenter!
    }

    // MARK: - Public Methods

    var isHintHidden: Bool {
        guard let hintPresenter else { return true }
        return MainActor.assumeIsolated { hintPresenter.isHintHidden }
    }

    func dismissHintDueToUserInteraction() {
        guard let hintPresenter else { return }
        Task { @MainActor in
            hintPresenter.dismissHintDueToUserInteraction()
        }
    }

    @objc func toggle(presenter: UIViewController, article: WMFArticle, theme: Theme) {
        self.presenter = presenter
        self.theme = theme

        let didSave = article.isSaved
        let didSaveOtherArticle = didSave && !isHintHidden && article != currentArticle
        let didUnsaveOtherArticle = !didSave && !isHintHidden && article != currentArticle

        guard !didUnsaveOtherArticle else { return }

        if didSaveOtherArticle {
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.getHintPresenter().resetHint()
                self.currentArticle = article
                self.showDefaultHint(article: article)
            }
            return
        }

        currentArticle = article

        if didSave {
            showDefaultHint(article: article)
        } else {
            guard let hintPresenter else { return }
            Task { @MainActor in
                hintPresenter.dismissHint()
            }
        }
    }

    // MARK: - Private Methods

    private func showDefaultHint(article: WMFArticle) {
        guard let presenter else { return }

        let title = hintButtonTitle(for: article)
        let icon = UIImage(named: "add-to-list")
        let articleURL = article.url

        let config = WMFHintConfig(
            title: title,
            icon: icon,
            duration: 13,
            tapAction: { @Sendable [weak self, articleURL] in
                Task { @MainActor in
                    guard let self, let articleURL else { return }
                    guard let article = self.dataStore.fetchArticle(with: articleURL) else { return }
                    self.performDefaultAction(article: article)
                }
            }
        )

        Task { @MainActor [weak self] in
            guard let self else { return }
            self.getHintPresenter().show(config: config, in: presenter)
        }
    }

    private func showConfirmationHintInPlace(readingList: ReadingList, image: UIImage?) {
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

        let config = WMFHintConfig(
            title: title,
            icon: image,
            duration: 13,
            buttonTitle: "→", // TODO: fix UI
            tapAction: { @Sendable [weak self, readingListObjectID] in
                Task { @MainActor in
                    guard let self,
                          let readingList = try? self.dataStore.viewContext.existingObject(with: readingListObjectID) as? ReadingList else { return }
                    self.performConfirmationAction(readingList: readingList)
                }
            },
            buttonAction: { @Sendable [weak self, readingListObjectID] in
                Task { @MainActor in
                    guard let self,
                          let readingList = try? self.dataStore.viewContext.existingObject(with: readingListObjectID) as? ReadingList else { return }
                    self.performConfirmationAction(readingList: readingList)
                }
            }
        )

        Task { @MainActor [weak self] in
            guard let self else { return }
            self.getHintPresenter().updateCurrentHint(with: config)
        }
    }

    private func hintButtonTitle(for article: WMFArticle) -> String {
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

        let addVC = AddArticlesToReadingListViewController(
            with: dataStore,
            articles: [article],
            moveFromReadingList: nil,
            theme: theme
        )
        addVC.delegate = self

        let nav = WMFComponentNavigationController(
            rootViewController: addVC,
            modalPresentationStyle: .overFullScreen
        )

        presenter.present(nav, animated: true)
    }

    private func performConfirmationAction(readingList: ReadingList) {
        guard let presenter else { return }

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

        presenter.present(nav, animated: true) { [weak self] in
            guard let self, let hintPresenter = self.hintPresenter else { return }
            Task { @MainActor in
                hintPresenter.dismissHint()
            }
        }
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

extension ReadingListHintPresenter: AddArticlesToReadingListDelegate {
    func addArticlesToReadingList(
        _ addArticlesToReadingList: AddArticlesToReadingListViewController,
        didAddArticles articles: [WMFArticle],
        to readingList: ReadingList
    ) {
        showConfirmationHintInPlace(readingList: readingList, image: nil)

        // try loading thumbnail, update if it succeeds
        let imageURL = articles.first?.imageURL(forWidth: ImageUtils.nearbyThumbnailWidth())
        guard let imageURL else { return }

        Task { [weak self] in
            guard let self else { return }
            let image = await self.loadImageOffMain(from: imageURL)
            await MainActor.run {
                self.showConfirmationHintInPlace(readingList: readingList, image: image)
            }
        }
    }

    func addArticlesToReadingListWillClose(_ addArticlesToReadingList: AddArticlesToReadingListViewController) {
        // No-op: confirmation state should be already applied in-place
    }
}

// MARK: - Themeable

extension ReadingListHintPresenter: Themeable {
    func apply(theme: Theme) {
        self.theme = theme
    }
}
