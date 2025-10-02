import WMFData

@objc(WMFRandomArticleViewController)
class RandomArticleViewController: ArticleViewController {
    static let diceButton: WMFRandomDiceButton = {
        return WMFRandomDiceButton(frame: CGRect(x: 0, y: 0, width: 184, height: 44))
    }()
    
    static let diceButtonItem: UIBarButtonItem = {
        return UIBarButtonItem(customView: diceButton)
    }()
    
    lazy var randomArticleFetcher: RandomArticleFetcher = {
        return RandomArticleFetcher()
    }()
    
    lazy var secondToolbar: UIToolbar = {
        let tb = UIToolbar()
        tb.translatesAutoresizingMaskIntoConstraints = false
        tb.isHidden = true
        return tb
    }()
        
    override func viewDidLoad() {
        super.viewDidLoad()
        setupSecondToolbar()
        setRandomButtonHidden(false, animated: false)
    }

    private var secondToolbarBottomConstraint: NSLayoutConstraint?
    func setupSecondToolbar() {
        view.addSubview(secondToolbar)
        
        let bottom = toolbarContainerView.topAnchor.constraint(equalTo: secondToolbar.bottomAnchor, constant: 10)
        NSLayoutConstraint.activate([
            bottom,
            view.safeAreaLayoutGuide.leadingAnchor.constraint(equalTo: secondToolbar.leadingAnchor),
            view.safeAreaLayoutGuide.trailingAnchor.constraint(equalTo: secondToolbar.trailingAnchor)
        ])
        
        self.secondToolbarBottomConstraint = bottom
        
        let leadingSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let trailingSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        secondToolbar.items = [leadingSpace, RandomArticleViewController.diceButtonItem, trailingSpace]
    }
    
    lazy var emptyFadeView: UIView = {
        let efv = UIView(frame: view.bounds)
        efv.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        efv.backgroundColor = .white
        efv.alpha = 0
        view.addSubview(efv)
        return efv
    }()

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        RandomArticleViewController.diceButton.addTarget(self, action: #selector(loadAndShowAnotherRandomArticle), for: .touchUpInside)
    }
    
    var viewHasAppeared: Bool = false
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        viewHasAppeared = true
        guard secondToolbar.items?.count ?? 0 == 0 else {
          return
        }
        secondToolbar.isHidden = false
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        RandomArticleViewController.diceButton.removeTarget(self, action: #selector(loadAndShowAnotherRandomArticle), for: .touchUpInside)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        configureViews(isRandomArticleLoading: false, animated: false)
    }
    
    func configureViews(isRandomArticleLoading: Bool, animated: Bool) {
        if isRandomArticleLoading {
            RandomArticleViewController.diceButton.roll()
        }
        
        RandomArticleViewController.diceButton.isEnabled = !isRandomArticleLoading
        
        let animations = {
            self.emptyFadeView.alpha = isRandomArticleLoading ? 1 : 0
        }
        
        if animated {
            UIView.animate(withDuration: 0.5, animations: animations)
        } else {
            animations()
        }
    }
    
    @objc func loadAndShowAnotherRandomArticle(_ sender: Any?) {
        guard let siteURL = articleURL.wmf_site else {
            return
        }
        configureViews(isRandomArticleLoading: true, animated: true)
        randomArticleFetcher.fetchRandomArticle(withSiteURL: siteURL) { (error, articleURL, summary) in
            DispatchQueue.main.async { [weak self] in
                guard
                    let self,
                    let articleURL,
                    let navigationController
                else {
                    WMFAlertManager.sharedInstance.showErrorAlert(error ?? RequestError.unexpectedResponse, sticky: true, dismissPreviousAlerts: true)
                    return
                }
                self.secondToolbar.items = []
                
                let randomCoordinator = RandomArticleCoordinator(navigationController: navigationController, articleURL: articleURL, siteURL: nil, dataStore: dataStore, theme: theme, source: .undefined, animated: true)
                randomCoordinator.start()
            }
        }
    }

    func setRandomButtonHidden(_ isRandomButtonHidden: Bool, animated: Bool) {
        secondToolbar.isHidden = isRandomButtonHidden
    }
    
    
    override func apply(theme: Theme) {
        super.apply(theme: theme)
        guard viewIfLoaded != nil else {
            return
        }
        (RandomArticleViewController.diceButton as Themeable).apply(theme: theme)
        emptyFadeView.backgroundColor = theme.colors.paperBackground
        secondToolbar.setBackgroundImage(theme.clearImage, forToolbarPosition: .any, barMetrics: .default)
        secondToolbar.setShadowImage(theme.clearImage, forToolbarPosition: .any)
    }
    
    var previousContentOffsetY: CGFloat = 0
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        super.scrollViewDidScroll(scrollView)
        guard viewHasAppeared else {
            return
        }
        
        var shouldHideRandomButton = true
        let newContentOffsetY = scrollView.contentOffset.y
        if secondToolbar.isHidden {
            let shouldShowRandomButton = newContentOffsetY <= 0 || (!scrollView.isTracking && scrollView.isDecelerating && newContentOffsetY < previousContentOffsetY && newContentOffsetY < (scrollView.contentSize.height - scrollView.bounds.size.height))
            shouldHideRandomButton = !shouldShowRandomButton
        } else if scrollView.isTracking || scrollView.isDecelerating {
            shouldHideRandomButton = newContentOffsetY > 0 && newContentOffsetY > previousContentOffsetY
        } else {
            shouldHideRandomButton = secondToolbar.isHidden
        }
        
        setRandomButtonHidden(shouldHideRandomButton, animated: true)
        previousContentOffsetY = newContentOffsetY
    }
}
