import UIKit
import WMF
import WMFComponents
import WMFData
import WMFNativeLocalizations

/// Owns the Discover interests screen. Get started and the Discover settings both push it.
/// Done commits the interests on the screen and tells the caller. Done is off while no interest
/// is selected. Back pops the screen and keeps the saved interests as they were.
final class DiscoverInterestsCoordinator: NSObject, Coordinator {

    let navigationController: UINavigationController
    private let dataStore: MWKDataStore
    private let interestsDataController: WMFDiscoverInterestsDataController

    /// Called on Done, after the interests on the screen are committed. The caller decides what
    /// happens to the screen and saves interests as the source.
    var didFinish: (() -> Void)?

    private(set) weak var interestsViewController: WMFHomeFeedInterestsSettingsViewController?
    private(set) var isFinishing = false

    init(
        navigationController: UINavigationController,
        dataStore: MWKDataStore,
        interestsDataController: WMFDiscoverInterestsDataController = .shared
    ) {
        self.navigationController = navigationController
        self.dataStore = dataStore
        self.interestsDataController = interestsDataController
        super.init()
    }

    // MARK: - Coordinator

    /// Reads the saved interests before the push, so the screen opens with the right header.
    @discardableResult
    func start() -> Bool {
        Task { [weak self] in
            guard let self else { return }
            let store = await WMFDiscoverInterestsStore.load(dataController: interestsDataController)
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
        let viewController = WMFHomeFeedInterestsSettingsViewController(viewModel: viewModel, doneButtonHandler: { [weak self] in
            self?.finish(store: store)
        })
        interestsViewController = viewController
        navigationController.pushViewController(viewController, animated: true)
    }

    // MARK: - Done

    /// Commits the interests on the screen first, so the list generator sees every tap. An empty
    /// set does nothing: Done is off then, and the screen stays. A second tap while the commit
    /// runs does nothing. When the commit fails the screen stays too, with a toast, so the reader
    /// can try again.
    func finish(store: WMFDiscoverInterestsStore) {
        guard !store.interests.isEmpty, !isFinishing else { return }
        isFinishing = true
        Task { [weak self] in
            do {
                try await store.commit()
                self?.isFinishing = false
                self?.didFinish?()
            } catch {
                self?.isFinishing = false
                WMFToastPresenter.shared.show(WMFToastConfig(title: CommonStrings.genericErrorDescription))
            }
        }
    }
}
