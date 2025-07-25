import UIKit
import WMF
import WMFComponents

final class NewArticleTabCoordinator: Coordinator {
    var navigationController: UINavigationController
    var dataStore: MWKDataStore
    var theme: Theme
    var dykFetcher: WMFFeedDidYouKnowFetcher
    private let sharedCache = SharedContainerCache(fileName: SharedContainerCacheCommonNames.dykCache)
    public var dykFacts: [WMFFeedDidYouKnow]? = nil

    init(navigationController: UINavigationController, dataStore: MWKDataStore, theme: Theme) {
        self.navigationController = navigationController
        self.dataStore = dataStore
        self.theme = theme
        dykFetcher = WMFFeedDidYouKnowFetcher()
    }

    @discardableResult
    func start() -> Bool {
        let viewModel = WMFNewArticleTabViewModel(text: "Placeholder", title: CommonStrings.newTab)
        let viewController = WMFNewArticleTabController(dataStore: dataStore, theme: theme, viewModel: viewModel)
        navigationController.pushViewController(viewController, animated: true)

        fetchDYK { facts in
            DispatchQueue.main.async {
                viewModel.facts = facts?.map { $0.html }
                viewModel.isLoading = false
            }
        }

        return true
    }
    
    private func fetchDYK(completion: @escaping ([WMFFeedDidYouKnow]?) -> Void) {
        guard let url = URL(string: "https://en.wikipedia.org") else {
            completion(nil)
            return
        }

        dykFetcher.fetchDidYouKnow(withSiteURL: url) { [weak self] error, facts in
            guard error == nil else {
                completion(nil)
                return
            }
            self?.dykFacts = facts
            completion(facts)
        }
    }
}
