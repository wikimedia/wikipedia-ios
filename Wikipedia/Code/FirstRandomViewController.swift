import WMFData

class FirstRandomViewController: UIViewController, Themeable {
    
    private let siteURL: URL
    private let dataStore: MWKDataStore
    private let theme: Theme

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
                    let randomCoordinator = RandomArticleCoordinator(navigationController: navigationController, articleURL: articleURL, siteURL: self.siteURL, dataStore: self.dataStore, theme: self.theme, source: .undefined, animated: false, replaceLastViewControllerInNavStack: true)
                    randomCoordinator.start()
                }
                
            }
        }
    }
    
    func apply(theme: Theme) {
        view.backgroundColor = theme.colors.paperBackground
    }
}
