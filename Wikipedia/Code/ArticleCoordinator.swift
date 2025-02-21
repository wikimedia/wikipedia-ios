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
    
    func start() {
        guard let articleVC = ArticleViewController(articleURL: articleURL, dataStore: dataStore, theme: theme, source: source) else {
            return
        }
        navigationController.pushViewController(articleVC, animated: true)
    }
}
