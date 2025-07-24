import UIKit
import WMF
import WMFComponents

final class NewArticleTabCoordinator: Coordinator {
    var navigationController: UINavigationController
    var dataStore: MWKDataStore
    var theme: Theme
    var dykFetcher: WMFFeedDidYouKnowFetcher

    init(navigationController: UINavigationController, dataStore: MWKDataStore, theme: Theme) {
        self.navigationController = navigationController
        self.dataStore = dataStore
        self.theme = theme
        dykFetcher = WMFFeedDidYouKnowFetcher()
    }

    @discardableResult
    func start() -> Bool {
        let dykfacts = fetchDYK()
        let facts: [String]? = dykfacts?.map { $0.html }
        
        let viewModel = WMFNewArticleTabViewModel(text: "Placeholder", title: CommonStrings.newTab, facts: facts)
        let viewController = WMFNewArticleTabController(dataStore: dataStore, theme: theme, viewModel: viewModel)
        navigationController.pushViewController(viewController, animated: true)
        
        return true
    }
    
    private func fetchDYK() -> [WMFFeedDidYouKnow]? {
        var dykfacts: [WMFFeedDidYouKnow]? = nil
        guard let url = URL(string: "en.wikipedia.org") else { return nil }
        dykFetcher.fetchDidYouKnow(withSiteURL: url) { [weak self] error, facts in
            guard self != nil, error == nil else { return }
            dykfacts = facts
        }
        return dykfacts
    }

}
