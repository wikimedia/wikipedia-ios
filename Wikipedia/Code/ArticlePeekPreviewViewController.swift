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
    }
    
    
}
