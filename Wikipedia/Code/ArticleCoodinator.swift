import UIKit


@objc
public enum ArticleSource: Int {
    case search
    case history
    case places
}

@objc(WMFArticleCoordinator)
final public class ArticleCoordinator: NSObject, Coordinator {

    // MARK: Coordinator Protocol Properties

    var navigationController: UINavigationController


    // MARK: Properties 

    var theme: Theme
    let dataStore: MWKDataStore
    let articleURL: URL
    let schemeHandler: SchemeHandler?


    init(navigationController: UINavigationController, theme: Theme, dataStore: MWKDataStore, articleURL: URL, schemeHandler: SchemeHandler? = nil) {
        self.navigationController = navigationController
        self.theme = theme
        self.dataStore = dataStore
        self.articleURL = articleURL
        self.schemeHandler = schemeHandler
    }

    func start() {

    }
}
