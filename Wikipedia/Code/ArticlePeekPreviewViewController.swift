import UIKit
import WMF

@objc (WMFArticlePeekPreviewViewController)
class ArticlePeekPreviewViewController: UIViewController, Peekable {
    
    fileprivate let articleURL: URL
    fileprivate let dataStore: MWKDataStore
    fileprivate var theme: Theme

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
    
    func fetchArticle() {
        guard let article = dataStore.fetchArticle(with: articleURL), article.capitalizedWikidataDescriptionOrSnippet != nil else {
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
    
    func updateView(with article: WMFArticle) {
        expandedArticleView.configure(article: article, displayType: .pageWithPreview, index: 0, count: 1, theme: theme, layoutOnly: false)
        expandedArticleView.isSaveButtonHidden = true
        expandedArticleView.extractLabel?.numberOfLines = 6
        expandedArticleView.frame = view.bounds
        expandedArticleView.isHeaderBackgroundViewHidden = false
        expandedArticleView.headerBackgroundColor = theme.colors.midBackground
        let preferredSize = self.view.systemLayoutSizeFitting(CGSize(width: self.view.bounds.size.width, height: UILayoutFittingCompressedSize.height), withHorizontalFittingPriority: UILayoutPriority.required, verticalFittingPriority: UILayoutPriority.fittingSizeLevel)
        self.preferredContentSize = expandedArticleView.sizeThatFits(preferredSize, apply: true)
        self.parent?.preferredContentSize = self.preferredContentSize
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        fetchArticle()
        view.addSubview(expandedArticleView)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        expandedArticleView.frame = view.bounds
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard viewIfLoaded != nil else {
            return
        }
        expandedArticleView.updateFonts(with: traitCollection)
    }

}
