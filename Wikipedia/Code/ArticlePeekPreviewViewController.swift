import UIKit

class ArticlePeekPreviewViewController: UIViewController {
    
    fileprivate let articleURL: URL
    fileprivate let dataStore: MWKDataStore
    fileprivate let theme: Theme
    
    required init(articleURL: URL, dataStore: MWKDataStore, theme: Theme) {
        self.articleURL = articleURL
        self.dataStore = dataStore
        self.theme = theme
        super.init(nibName: "ArticlePeekPreviewViewController", bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        return nil
    }
    
    func fetchArticle() {
       let articleFetcher = WMFArticleFetcher()
    }
    
    
}
