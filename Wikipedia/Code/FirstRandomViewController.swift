import WMFData

class FirstRandomViewController: UIViewController, Themeable {
    
    private let siteURL: URL
    private let dataStore: MWKDataStore
    private let theme: Theme
    var didYouKnowProvider: WMFArticleTabsDataController.DidYouKnowProvider?

    init(siteURL: URL, dataStore: MWKDataStore, theme: Theme) {
        self.siteURL = siteURL
        self.dataStore = dataStore
        self.theme = theme
        
        super.init(nibName: nil, bundle: nil)
        self.hidesBottomBarWhenPushed = true
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        apply(theme: theme)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        let fetcher = RandomArticleFetcher()
        fetcher.fetchRandomArticle(withSiteURL: siteURL) { [weak self] error, articleURL, articleSummary in
            DispatchQueue.main.async {
                
                guard let self else { return }
                
                if error != nil || articleURL == nil {
                    WMFAlertManager.sharedInstance.showErrorAlert((error ?? Fetcher.unexpectedResponseError), sticky: false, dismissPreviousAlerts: false)
                    return
                }
                
                if let navigationController = self.navigationController {
                    let randomCoordinator = RandomArticleCoordinator(navigationController: navigationController, articleURL: articleURL, siteURL: self.siteURL, dataStore: self.dataStore, theme: self.theme, source: .undefined, animated: false, replaceLastViewControllerInNavStack: true, linkDelegate: self)
                    randomCoordinator.didYouKnowProvider = self.didYouKnowProvider
                    randomCoordinator.start()
                }
                
            }
        }
    }
    
    func apply(theme: Theme) {
        view.backgroundColor = theme.colors.paperBackground
    }
}

extension FirstRandomViewController: UITextViewDelegate {
    func tappedLink(_ url: URL, sourceTextView: UITextView) {
        guard let url = URL(string: url.absoluteString) else {
            return
        }

        let legacyNavigateAction = { [weak self] in
            guard let self else { return }
            let userInfo: [AnyHashable : Any] = [RoutingUserInfoKeys.source: RoutingUserInfoSourceValue.talkPage.rawValue]
            navigate(to: url.absoluteURL, userInfo: userInfo)
        }

        // first try to navigate using LinkCoordinator. If it fails, use the legacy approach.
        let navController = self.navigationController
            ?? self.parent?.navigationController

        if let navController {
            let linkCoordinator = LinkCoordinator(navigationController: navController, url: url.absoluteURL, dataStore: nil, theme: theme, articleSource: .undefined)
            let success = linkCoordinator.start()


            guard success else {
                legacyNavigateAction()
                return
            }
        } else {
            legacyNavigateAction()
        }
    }

    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        tappedLink(URL, sourceTextView: textView)
        return false
    }
}
