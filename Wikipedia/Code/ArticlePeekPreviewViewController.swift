import UIKit
import WMF

@objc(WMFArticlePeekPreviewViewController)
class ArticlePeekPreviewViewController: UIViewController, Peekable {
    
    let articleURL: URL
    fileprivate let dataStore: MWKDataStore
    fileprivate var theme: Theme
    fileprivate let activityIndicatorView: UIActivityIndicatorView = UIActivityIndicatorView(style: UIActivityIndicatorView.Style.whiteLarge)
    fileprivate let expandedArticleView = ArticleFullWidthImageCollectionViewCell()

    @objc required init(articleURL: URL, dataStore: MWKDataStore, theme: Theme) {
        self.articleURL = articleURL
        self.dataStore = dataStore
        self.theme = theme
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        return nil
    }
    
    private var isFetched = false
    @objc func fetchArticle(_ completion:(() -> Void)? = nil ) {
        assert(Thread.isMainThread)
        guard !isFetched else {
            completion?()
            return
        }
        isFetched = true
        guard let key = articleURL.wmf_inMemoryKey else {
            completion?()
            return
        }
        dataStore.articleSummaryController.updateOrCreateArticleSummaryForArticle(withKey: key) { (article, _) in
            defer {
                completion?()
            }
            guard let article = article else {
                self.activityIndicatorView.stopAnimating()
                return
            }
            self.updateView(with: article)
        }
    }
    
    func updatePreferredContentSize(for contentWidth: CGFloat) {
        var updatedContentSize = expandedArticleView.sizeThatFits(CGSize(width: contentWidth, height: UIView.noIntrinsicMetric), apply: true)
        updatedContentSize.width = contentWidth // extra protection to ensure this stays == width
        parent?.preferredContentSize = updatedContentSize
        preferredContentSize = updatedContentSize
    }
    
    fileprivate func updateView(with article: WMFArticle) {
        expandedArticleView.configure(article: article, displayType: .pageWithPreview, index: 0, theme: theme, layoutOnly: false)
        expandedArticleView.isSaveButtonHidden = true
        expandedArticleView.extractLabel?.numberOfLines = 5
        expandedArticleView.frame = view.bounds
        expandedArticleView.isHeaderBackgroundViewHidden = false
        expandedArticleView.headerBackgroundColor = theme.colors.midBackground
        expandedArticleView.isHidden = false

        activityIndicatorView.stopAnimating()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = theme.colors.paperBackground
        activityIndicatorView.style = theme.isDark ? .white : .gray
        activityIndicatorView.startAnimating()
        view.addSubview(activityIndicatorView)
        expandedArticleView.isHidden = true
        view.addSubview(expandedArticleView)
        expandedArticleView.updateFonts(with: traitCollection)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        fetchArticle {
            self.updatePreferredContentSize(for: self.view.bounds.width)
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        expandedArticleView.frame = view.bounds
        activityIndicatorView.center = CGPoint(x: view.bounds.midX, y: view.bounds.midY)
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard viewIfLoaded != nil else {
            return
        }
        expandedArticleView.updateFonts(with: traitCollection)
    }

}
