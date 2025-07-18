import UIKit
import WMF
import WMFComponents

final class NewArticleTabCoordinator: Coordinator {
    var navigationController: UINavigationController
    var dataStore: MWKDataStore
    var theme: Theme
    

    init(navigationController: UINavigationController, dataStore: MWKDataStore, theme: Theme) {
        self.navigationController = navigationController
        self.dataStore = dataStore
        self.theme = theme
    }

    var recentSearches: MWKRecentSearchList? {
        return self.dataStore.recentSearchList
    }

    private lazy var recentSearchTerms: [WMFRecentlySearchedViewModel.RecentSearchTerm] = { // limit to three
        guard let recent = recentSearches else { return [] }
        return recent.entries.map {
            WMFRecentlySearchedViewModel.RecentSearchTerm(text: $0.searchTerm)
        }
    }()

    private lazy var deleteItemAction: (Int) -> Void = { [weak self] index in
        guard
            let self = self,
            let entry = self.recentSearches?.entries[index]
        else {
            return
        }

        Task {
            self.dataStore.recentSearchList.removeEntry(entry)
            self.dataStore.recentSearchList.save()
            // TODO:  reload the vc
        }
    }

    lazy var selectAction: (WMFRecentlySearchedViewModel.RecentSearchTerm) -> Void = { [weak self] term in
       // TODO: pass it to the vc
    }

    private lazy var deleteAllAction: () -> Void = { [weak self] in
        guard let self = self else { return }

        Task {
            self.dataStore.recentSearchList.removeAllEntries()
            self.dataStore.recentSearchList.save()
            // TODO:  reload the vc
        }

    }

    lazy var didPressClearRecentSearches: () -> Void = { [weak self] in
        // TODO: add dialog, move strings from Search VC to Common strings to be reuse
    }

    private lazy var recentSearchesViewModel: WMFRecentlySearchedViewModel = {
        let localizedStrings = WMFRecentlySearchedViewModel.LocalizedStrings(
            title: CommonStrings.recentlySearchedTitle,
            noSearches: CommonStrings.recentlySearchedEmpty,
            clearAll: CommonStrings.clearTitle,
            deleteActionAccessibilityLabel: CommonStrings.deleteActionTitle
        )
        return WMFRecentlySearchedViewModel(recentSearchTerms: recentSearchTerms, localizedStrings: localizedStrings, deleteAllAction: didPressClearRecentSearches, deleteItemAction: deleteItemAction, selectAction: selectAction)
    }()

    @discardableResult
    func start() -> Bool {
        let viewModel = WMFNewArticleTabViewModel(title: CommonStrings.newTab, recentlySearchedViewModel: recentSearchesViewModel)
        let viewController = WMFNewArticleTabController(dataStore: dataStore, theme: theme, viewModel: viewModel)
        navigationController.pushViewController(viewController, animated: true)
        return true
    }

}
