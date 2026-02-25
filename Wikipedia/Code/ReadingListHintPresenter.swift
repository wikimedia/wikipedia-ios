import UIKit
import WMFComponents
@preconcurrency import WMFData

// TODO: Rename hint to something that makes more sense, it's just a reading list helper now
@objc(WMFReadingListHintPresenter)
class ReadingListHintPresenter: NSObject {

    // MARK: - Properties

    private let dataStore: MWKDataStore
    private var hintPresenter: WMFHintPresenter?
    private weak var presenter: UIViewController?
    private var currentArticle: WMFArticle?
    private var currentReadingList: ReadingList?
    private var pendingConfirmation: (article: WMFArticle, readingList: ReadingList, imageURL: URL?)?
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
        guard let hintPresenter = hintPresenter else { return true }
        return MainActor.assumeIsolated {
            hintPresenter.isHintHidden
        }
    }

    func dismissHintDueToUserInteraction() {
        guard let hintPresenter = hintPresenter else { return }
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

        guard !didUnsaveOtherArticle else {
            return
        }

        guard !didSaveOtherArticle else {
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
            guard let hintPresenter = hintPresenter else { return }
            Task { @MainActor in
                hintPresenter.dismissHint()
            }
        }
    }

    // MARK: - Private Methods

    private func showDefaultHint(article: WMFArticle) {
        guard let presenter = presenter else { return }

        let title = hintButtonTitle(for: article)
        let icon = UIImage(named: "add-to-list")

        // Capture URL instead of article to avoid Sendable warnings
        let articleURL = article.url

        let config = WMFHintConfig(
            title: title,
            icon: icon,
            duration: 13,
            tapAction: { @Sendable [weak self, articleURL] in
                Task { @MainActor in
                    guard let self, let articleURL else { return }
                    guard let article = self.dataStore.fetchArticle(with: articleURL) else { return }
                    // Dismiss the current hint immediately on tap so it doesn't linger behind the modal
//                    self.getHintPresenter().dismissHint()
                    self.performDefaultAction(article: article)
                }
            }
        )

        Task { @MainActor [weak self] in
            guard let self else { return }
            self.getHintPresenter().show(config: config, in: presenter)
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
            return WMFLocalizedString("reading-list-add-generic-hint-title",
                                    value: "Add this article to a reading list?",
                                    comment: "Title of the reading list hint that appears after an article is saved.")
        }

        return String.localizedStringWithFormat(
            WMFLocalizedString("reading-list-add-hint-title",
                             value: "Add \"%1$@\" to a reading list?",
                             comment: "Title of the reading list hint that appears after an article is saved. %1$@ will be replaced with the saved article title"),
            articleTitle
        )
    }

    private func performDefaultAction(article: WMFArticle) {
        guard let presenter = presenter else { return }

        let addArticlesToReadingListViewController = AddArticlesToReadingListViewController(
            with: dataStore,
            articles: [article],
            moveFromReadingList: nil,
            theme: theme
        )
        addArticlesToReadingListViewController.delegate = self

        let navigationController = WMFComponentNavigationController(
            rootViewController: addArticlesToReadingListViewController,
            modalPresentationStyle: .overFullScreen
        )

        // Don't dismiss hint - let modal present over it
        presenter.present(navigationController, animated: true)
    }

    private func performConfirmationAction(readingList: ReadingList) {
        guard let presenter = presenter else { return }

        let readingListDetailViewController = ReadingListDetailViewController(
            for: readingList,
            with: dataStore,
            displayType: .modal
        )
        readingListDetailViewController.apply(theme: theme)

        let navigationController = WMFComponentNavigationController(
            rootViewController: readingListDetailViewController,
            modalPresentationStyle: .overFullScreen
        )

        themeableNavigationController = navigationController

        presenter.present(navigationController, animated: true) { [weak self] in
            guard let self, let hintPresenter = self.hintPresenter else { return }
            Task { @MainActor in
                hintPresenter.dismissHint()
            }
        }
    }
}

// MARK: - AddArticlesToReadingListDelegate
// TODO: cleanup prints
extension ReadingListHintPresenter: AddArticlesToReadingListDelegate {
    func addArticlesToReadingList(_ addArticlesToReadingList: AddArticlesToReadingListViewController, didAddArticles articles: [WMFArticle], to readingList: ReadingList) {
        print("🔍 addArticlesToReadingList called")
        // Update state and defer confirmation until modal closes
        guard let name = readingList.name else {
            print("🔍 ERROR: reading list name is nil")
            return
        }

        print("🔍 Reading list name: \(name)")
        currentReadingList = readingList

        let imageURL = articles.first?.imageURL(forWidth: ImageUtils.nearbyThumbnailWidth())
        print("🔍 Image URL: \(imageURL?.absoluteString ?? "nil")")

        // Store pending confirmation info to show after modal closes
        if let firstArticle = articles.first {
            pendingConfirmation = (firstArticle, readingList, imageURL)
        }
    }

    func addArticlesToReadingListWillClose(_ addArticlesToReadingList: AddArticlesToReadingListViewController) {
        // Show confirmation hint after modal closes, ensuring a fresh timer and visibility
        guard let pending = pendingConfirmation else {
            return
        }

        presenter?.dismiss(animated: true) { [weak self] in
            self?.showConfirmationHint(for: pending.readingList, imageURL: pending.imageURL)
            self?.pendingConfirmation = nil
        }
    }

    private func showConfirmationHint(for readingList: ReadingList, imageURL: URL?) {
        guard let presenter = presenter else { return }
        guard let name = readingList.name else { return }

        let title = String.localizedStringWithFormat(
            WMFLocalizedString("reading-lists-article-added-confirmation",
                               value: "Article added to \"%1$@\"",
                               comment: "Confirmation shown after the user adds an article to a list. %1$@ will be replaced with the name of the list the article was added to."),
            name
        )

        let readingListObjectID = readingList.objectID

        // Show a fresh hint with no icon first
        let config = WMFHintConfig(
            title: title,
            icon: nil,
            duration: 13,
            buttonTitle: "→",
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
            self.getHintPresenter().show(config: config, in: presenter)
        }

        // Optionally load the image asynchronously, then update the visible hint
        if let imageURL = imageURL {
            Task.detached(priority: .userInitiated) {
                if let data = try? Data(contentsOf: imageURL),
                   let image = UIImage(data: data) {
                    await MainActor.run { [weak self] in
                        guard let self else { return }

                        let configWithImage = WMFHintConfig(
                            title: title,
                            icon: image,
                            duration: 13,
                            buttonTitle: "→", // Todo: chevron or talk to design
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

                        self.getHintPresenter().updateCurrentHint(with: configWithImage)
                    }
                }
            }
        }
    }
}

// MARK: - Themeable

extension ReadingListHintPresenter: Themeable {
    func apply(theme: Theme) {
        self.theme = theme
    }
}

// MARK: - Context Key
// TODO: check if we still need this - it was added to pass article info to the hint presenter when the hint is tapped, but we may be able to capture that info in the tap action closure instead to avoid using context keys
extension ReadingListHintPresenter {
    @objc public static let ContextArticleKey = "ContextArticleKey"
}

