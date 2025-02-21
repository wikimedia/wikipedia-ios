final class ArticleCoordinator: Coordinator {
    let navigationController: UINavigationController
    private let articleURL: URL
    private let dataStore: MWKDataStore
    var theme: Theme
    private let source: ArticleSource
    
    init(navigationController: UINavigationController, articleURL: URL, dataStore: MWKDataStore, theme: Theme, source: ArticleSource) {
        self.navigationController = navigationController
        self.articleURL = articleURL
        self.dataStore = dataStore
        self.theme = theme
        self.source = source
    }
    
    @discardableResult
    func start() -> Bool {
        guard let articleVC = ArticleViewController(articleURL: articleURL, dataStore: dataStore, theme: theme, source: source) else {
            return false
        }
        navigationController.pushViewController(articleVC, animated: true)
        return true
    }
}
