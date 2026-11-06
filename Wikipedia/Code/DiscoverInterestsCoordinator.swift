import UIKit
import WMF
import WMFComponents
import WMFData
import WMFNativeLocalizations

/// Owns the Discover interests screen. Get started and the Discover settings both push it.
/// Back never pops the screen on its own: with at least one interest the caller moves on with
/// interests as the source, with none an alert asks the reader to select interests or to build
/// Discover from saved articles or reading history instead.
final class DiscoverInterestsCoordinator: NSObject, Coordinator {

    let navigationController: UINavigationController
    private let dataStore: MWKDataStore
    private let readingListDataController: WMFDiscoverReadingListDataController
    private let interestsDataController: WMFDiscoverInterestsDataController

    /// Called on Back, after the interests on the screen are committed: interests when at least
    /// one is selected, saved articles or reading history when the reader picked one on the alert.
    /// The caller decides what happens to the screen and saves the source.
    var didChooseSource: ((WMFDiscoverSource) -> Void)?

    private(set) weak var interestsViewController: WMFHomeFeedInterestsSettingsViewController?
    /// Read when the screen opens. The sources the alert offers instead of interests, in the
    /// order of the source screen.
    private var alternativeSources: [WMFDiscoverSource] = []

    init(
        navigationController: UINavigationController,
        dataStore: MWKDataStore,
        readingListDataController: WMFDiscoverReadingListDataController = .shared,
        interestsDataController: WMFDiscoverInterestsDataController = .shared
    ) {
        self.navigationController = navigationController
        self.dataStore = dataStore
        self.readingListDataController = readingListDataController
        self.interestsDataController = interestsDataController
        super.init()
    }

    // MARK: - Coordinator

    /// Reads the saved interests and the sources before the push, so the screen opens with the
    /// right header and Back knows which alert to show.
    @discardableResult
    func start() -> Bool {
        Task { [weak self] in
            guard let self else { return }
            let store = await WMFDiscoverInterestsStore.load(dataController: interestsDataController)
            let availableSources = (try? await readingListDataController.availableSources()) ?? []
            alternativeSources = availableSources.filter { $0 != .interests }
            showInterests(store: store)
        }
        return true
    }

    private func showInterests(store: WMFDiscoverInterestsStore) {
        let language = WMFDataEnvironment.current.primaryAppLanguage ?? WMFLanguage(languageCode: "en", languageVariantCode: nil)
        let searchLanguages = dataStore.languageLinkController.preferredLanguages.map {
            WMFLanguage(languageCode: $0.languageCode, languageVariantCode: $0.languageVariantCode)
        }
        // Instrumentation lands with T440585.
        let viewModel = WMFHomeFeedInterestsSettingsViewModel(
            discoverInterestsStore: store,
            project: .wikipedia(language),
            searchLanguages: searchLanguages,
            logDidTapTopic: {},
            logDidTapArticle: {},
            logDidTapDeselectAll: {}
        )
        let viewController = WMFHomeFeedInterestsSettingsViewController(viewModel: viewModel)
        viewController.shouldPopOnBack = { [weak self] in
            self?.handleBack(store: store) ?? true
        }
        interestsViewController = viewController
        navigationController.pushViewController(viewController, animated: true)
    }

    // MARK: - Back

    func handleBack(store: WMFDiscoverInterestsStore) -> Bool {
        if store.interests.isEmpty {
            let alert = makeSelectInterestsAlert(alternativeSources: alternativeSources, store: store)
            navigationController.present(alert, animated: true)
        } else {
            chooseSource(.interests, store: store)
        }
        return false
    }

    func makeSelectInterestsAlert(alternativeSources: [WMFDiscoverSource], store: WMFDiscoverInterestsStore) -> UIAlertController {
        let alert = UIAlertController(title: Self.alertTitle, message: Self.alertMessage(alternativeSources: alternativeSources), preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: Self.alertSelectInterests, style: .cancel))
        for source in alternativeSources where source != .interests {
            alert.addAction(UIAlertAction(title: Self.alertActionTitle(source: source), style: .default) { [weak self] _ in
                self?.chooseSource(source, store: store)
            })
        }
        return alert
    }

    static func alertMessage(alternativeSources: [WMFDiscoverSource]) -> String {
        let hasSaved = alternativeSources.contains(.saved)
        let hasHistory = alternativeSources.contains(.history)
        switch (hasSaved, hasHistory) {
        case (true, true): return alertMessageWithSavedAndHistory
        case (true, false): return alertMessageWithSaved
        case (false, true): return alertMessageWithHistory
        case (false, false): return alertMessageWithoutSources
        }
    }

    static func alertActionTitle(source: WMFDiscoverSource) -> String {
        switch source {
        case .saved: return alertUseSavedArticles
        case .history, .interests: return alertUseReadingHistory
        }
    }

    /// Commits the interests on the screen first, so the list generator sees every tap.
    func chooseSource(_ source: WMFDiscoverSource, store: WMFDiscoverInterestsStore) {
        Task { [weak self] in
            try? await store.commit()
            self?.didChooseSource?(source)
        }
    }

    // MARK: - Strings

    static let alertTitle = WMFLocalizedString("discover-interests-alert-title", value: "Select at least one interest", comment: "Title of the alert shown when the reader leaves the Discover interests screen without any interest selected.")
    static let alertMessageWithHistory = WMFLocalizedString("discover-interests-alert-message-history", value: "Discover is built from your interests. If you don't select any, Discover will be built from your reading history on this device.", comment: "Message of the alert shown when the reader leaves the Discover interests screen without any interest selected and has reading history on this device.")
    static let alertMessageWithSaved = WMFLocalizedString("discover-interests-alert-message-saved", value: "Discover is built from your interests. If you don't select any, Discover will be built from your saved articles.", comment: "Message of the alert shown when the reader leaves the Discover interests screen without any interest selected and has saved articles but no reading history on this device.")
    static let alertMessageWithSavedAndHistory = WMFLocalizedString("discover-interests-alert-message-saved-history", value: "Discover is built from your interests. If you don't select any, Discover will be built from your saved articles or your reading history on this device.", comment: "Message of the alert shown when the reader leaves the Discover interests screen without any interest selected and has both saved articles and reading history on this device.")
    static let alertMessageWithoutSources = WMFLocalizedString("discover-interests-alert-message-none", value: "Discover needs at least one interest to build your reading list.", comment: "Message of the alert shown when the reader leaves the Discover interests screen without any interest selected and has neither saved articles nor reading history on this device.")
    static let alertSelectInterests = WMFLocalizedString("discover-interests-alert-select", value: "Select interests", comment: "Title of the alert button that keeps the reader on the Discover interests screen.")
    static let alertUseSavedArticles = WMFLocalizedString("discover-interests-alert-use-saved", value: "Use saved articles", comment: "Title of the alert button that builds Discover from the saved articles instead of interests.")
    static let alertUseReadingHistory = WMFLocalizedString("discover-interests-alert-use-history", value: "Use reading history", comment: "Title of the alert button that builds Discover from the reading history on this device instead of interests.")
}
