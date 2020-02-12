import Foundation

@objc (WMFRandomArticleViewController)
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
        
    override func viewDidLoad() {
        super.viewDidLoad()
        setupSecondToolbar()
        setRandomButtonHidden(false, animated: false)
    }

    func setupSecondToolbar() {
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
        UIView.performWithoutAnimation {
            setupSecondToolbar()
            setSecondToolbarHidden(true, animated: false)
        }
        setSecondToolbarHidden(false, animated: true)
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
            DispatchQueue.main.async {
                guard
                    let articleURL = articleURL,
                    let randomVC = RandomArticleViewController(articleURL: articleURL, dataStore: self.dataStore, theme: self.theme)
                else {
                    self.alertManager.showErrorAlert(error ?? RequestError.unexpectedResponse, sticky: true, dismissPreviousAlerts: true)
                    return
                }
                self.secondToolbar.items = []
                self.push(randomVC, animated: true)
            }
        }
    }

    func setRandomButtonHidden(_ isRandomButtonHidden: Bool, animated: Bool) {
        if isSecondToolbarHidden != isRandomButtonHidden {
            setSecondToolbarHidden(isRandomButtonHidden, animated: animated)
        }
    }
    
    
    override func apply(theme: Theme) {
        super.apply(theme: theme)
        guard viewIfLoaded != nil else {
            return
        }
        (RandomArticleViewController.diceButton as Themeable).apply(theme: theme)
        emptyFadeView.backgroundColor = theme.colors.paperBackground
    }
    
    var previousContentOffsetY: CGFloat = 0
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        super.scrollViewDidScroll(scrollView)
        guard viewHasAppeared else {
            return
        }
        
        var shouldHideRandomButton = true
        let newContentOffsetY = scrollView.contentOffset.y
        if isSecondToolbarHidden {
            let shouldShowRandomButton = newContentOffsetY <= 0 || (!scrollView.isTracking && scrollView.isDecelerating && newContentOffsetY < previousContentOffsetY && newContentOffsetY < (scrollView.contentSize.height - scrollView.bounds.size.height))
            shouldHideRandomButton = !shouldShowRandomButton
        } else if (scrollView.isTracking || scrollView.isDecelerating) {
            shouldHideRandomButton = newContentOffsetY > 0 && newContentOffsetY > previousContentOffsetY
        } else {
            shouldHideRandomButton = isSecondToolbarHidden
        }
        
        setRandomButtonHidden(shouldHideRandomButton, animated: true)
        previousContentOffsetY = newContentOffsetY
    }
}
