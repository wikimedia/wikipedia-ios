import UIKit
import NotificationCenter
import WMFUI
import WMFModel

class WMFTodayTopReadWidgetViewController: UIViewController, NCWidgetProviding {
    
    let articlePreviewFetcher = WMFArticlePreviewFetcher()
    let mostReadFetcher = WMFMostReadTitleFetcher()

    override func viewDidLoad() {
        super.viewDidLoad()
        widgetPerformUpdate { (result) in
            
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func widgetPerformUpdate(completionHandler: ((NCUpdateResult) -> Void)) {

        let siteURL = NSURL.wmf_URLWithDefaultSiteAndCurrentLocale()

        mostReadFetcher.fetchMostReadTitlesForSiteURL(siteURL, date: NSDate().wmf_bestMostReadFetchDate()).then { (result) -> AnyPromise in
            
            guard let mostReadTitlesResponse = result as? WMFMostReadTitlesResponseItem else {
                completionHandler(.NoData)
                return AnyPromise(value: nil)
            }
            
            let articleURLs = mostReadTitlesResponse.articles.map({ (article) -> NSURL in
                return siteURL.wmf_URLWithTitle(article.titleText)
            })
            
            return self.articlePreviewFetcher.fetchArticlePreviewResultsForArticleURLs(articleURLs, siteURL: siteURL, extractLength: 0, thumbnailWidth: UIScreen.mainScreen().wmf_listThumbnailWidthForScale().unsignedIntegerValue)
        }.then { (result) -> AnyPromise in
            guard let articlePreviewResponse = result as? [MWKSearchResult] else {
                completionHandler(.NoData)
                return AnyPromise(value: nil)
            }
            
            print("\(articlePreviewResponse)")
            
            completionHandler(.NewData)
            return AnyPromise(value: articlePreviewResponse)
        }

    }
    
}
