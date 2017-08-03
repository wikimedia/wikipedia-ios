import UIKit
import NotificationCenter
import WMF

class FeaturedArticleWidget: UIViewController, NCWidgetProviding {
    let collapsedArticleView = ArticleRightAlignedImageCollectionViewCell()
    let expandedArticleView = ArticleFullWidthImageCollectionViewCell()

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.translatesAutoresizingMaskIntoConstraints = false

        collapsedArticleView.frame = view.bounds
        view.addSubview(collapsedArticleView)

        expandedArticleView.frame = view.bounds
        view.addSubview(expandedArticleView)
    }
    
    var isEmptyViewHidden = true
    
    func widgetPerformUpdate(completionHandler: @escaping (NCUpdateResult) -> Void) {
        guard let session = SessionSingleton.sharedInstance(),
            let userStore = session.dataStore,
            let siteURL = MWKLanguageLinkController.sharedInstance().appLanguage?.siteURL(),
            let featuredContentGroup = userStore.viewContext.group(of: .featuredArticle, for: Date(), siteURL: siteURL),
            let articleURL = featuredContentGroup.content?.first as? URL,
            let article = userStore.fetchArticle(with: articleURL) else {
                isEmptyViewHidden = false
                completionHandler(.failed)
                return
        }
        
        isEmptyViewHidden = true
        expandedArticleView.configure(article: article, displayType: featuredContentGroup.displayTypeForItem(at: 0), index: 0, count: 1, theme: Theme.dark, layoutOnly: false)
        updateView()
        completionHandler(.newData)
    }
    
    func updateView() {
        var maximumSize = CGSize(width: view.bounds.size.width, height: UIViewNoIntrinsicMetric)
        var isExpanded = false
        if let context = extensionContext {
            if #available(iOSApplicationExtension 10.0, *) {
                context.widgetLargestAvailableDisplayMode = .expanded
                isExpanded = context.widgetActiveDisplayMode == .expanded
                maximumSize = context.widgetMaximumSize(for: context.widgetActiveDisplayMode)
            } else {
                isExpanded = true
                maximumSize = UIScreen.main.bounds.size
            }
        }
        updateView(maximumSize: maximumSize, isExpanded: isExpanded)
    }
    
    func updateView(maximumSize: CGSize, isExpanded: Bool) {
        //collapsedArticleView.configure(article: article, displayType: .page, index: 0, count: 1, theme: Theme.dark, layoutOnly: false)
        preferredContentSize = expandedArticleView.sizeThatFits(maximumSize, apply: true)
        expandedArticleView.frame = CGRect(origin: .zero, size:preferredContentSize)
        view.layoutIfNeeded()
    }
    
    @available(iOSApplicationExtension 10.0, *)
    func widgetActiveDisplayModeDidChange(_ activeDisplayMode: NCWidgetDisplayMode, withMaximumSize maxSize: CGSize) {
        updateView(maximumSize: maxSize, isExpanded: activeDisplayMode == .expanded)
    }
    
}
