import UIKit
import WMF

@objc (WMFArticlePeekPreviewViewController)
class ArticlePeekPreviewViewController: UIViewController {
    
    fileprivate let articleURL: URL
    fileprivate let dataStore: MWKDataStore
    fileprivate let theme: Theme
    
    @objc required init(articleURL: URL, dataStore: MWKDataStore, theme: Theme) {
        self.articleURL = articleURL
        self.dataStore = dataStore
        self.theme = theme
        super.init(nibName: "ArticlePeekPreviewViewController", bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        return nil
    }
    
    func fetchArticle() {
       let articleFetcher = WMFArticleFetcher(dataStore: dataStore)
        articleFetcher.fetchLatestVersionOfArticle(with: articleURL, forceDownload: false, saveToDisk: false, progress: nil, failure: { (error) in
            print("Error fetching article \(error)")
        }) { (article) in
            print("Success! Title: \(article.displaytitle)")
            
        }
    }
    
    override func viewDidLoad() {
        fetchArticle()
        updateFonts()
    }
    
    func updateFonts() {
        titleLabel.setFont(with: .georgia, style: .title1, traitCollection: traitCollection)
        descriptionLabel.setFont(with: .system, style: .subheadline, traitCollection: traitCollection)
        textLabel.setFont(with: .system, style: .subheadline, traitCollection: traitCollection)
        textLabel.lineBreakMode = .byTruncatingTail
        
        if #available(iOS 11.0, *) {
            leadImageView.accessibilityIgnoresInvertColors = true
        }
    }
}
