import UIKit
import WMF

class ArticlePeekPreviewViewController: UIViewController, Peekable {
    
    fileprivate let articleURL: URL
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
    
    fileprivate func fetchArticle() {
        guard let article = dataStore.fetchArticle(with: articleURL) else {
            dataStore.viewContext.wmf_updateOrCreateArticleSummariesForArticles(withURLs: [articleURL], completion: { (articles) in
                guard let first = articles.first else {
                    return
                }
                self.updateView(with: first)
            })
            return
        }
        updateView(with: article)
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
        
        let preferredSize = self.view.systemLayoutSizeFitting(CGSize(width: self.view.bounds.size.width, height: UIView.layoutFittingCompressedSize.height), withHorizontalFittingPriority: UILayoutPriority.required, verticalFittingPriority: UILayoutPriority.fittingSizeLevel)
        self.preferredContentSize = expandedArticleView.sizeThatFits(preferredSize, apply: true)
        self.parent?.preferredContentSize = self.preferredContentSize
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = theme.colors.paperBackground

        activityIndicatorView.style = theme.isDark ? .white : .gray
        activityIndicatorView.startAnimating()

        view.addSubview(activityIndicatorView)
        expandedArticleView.isHidden = true
        view.addSubview(expandedArticleView)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        fetchArticle()
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
