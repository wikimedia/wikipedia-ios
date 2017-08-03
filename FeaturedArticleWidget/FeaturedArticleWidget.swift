import UIKit
import NotificationCenter
import WMF

class FeaturedArticleWidget: UIViewController, NCWidgetProviding {
    let collapsedArticleView = ArticleRightAlignedImageCollectionViewCell()
    let expandedArticleView = ArticleFullWidthImageCollectionViewCell()

    var isExpanded = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.translatesAutoresizingMaskIntoConstraints = false

        collapsedArticleView.frame = view.bounds
        view.addSubview(collapsedArticleView)

        expandedArticleView.frame = view.bounds
        view.addSubview(expandedArticleView)
        
        updateView()
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
        collapsedArticleView.configure(article: article, displayType: .page, index: 0, count: 1, shouldAdjustMargins: false, shouldShowSeparators: false, theme: Theme.widget, layoutOnly: false)
        expandedArticleView.configure(article: article, displayType: featuredContentGroup.displayTypeForItem(at: 0), index: 0, count: 1, theme: Theme.widget, layoutOnly: false)
        updateView()
        completionHandler(.newData)
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: { (context) in
            self.expandedArticleView.alpha = self.isExpanded ? 1 : 0
            self.collapsedArticleView.alpha =  self.isExpanded ? 0 : 1
        }) { (context) in
            
        }
    }
    func updateView() {
        var maximumSize = CGSize(width: view.bounds.size.width, height: UIViewNoIntrinsicMetric)
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
        let sizeThatFits: CGSize
        if isExpanded {
            sizeThatFits = expandedArticleView.sizeThatFits(CGSize(width: maximumSize.width, height:UIViewNoIntrinsicMetric), apply: true)
        } else {
            sizeThatFits = collapsedArticleView.sizeThatFits(CGSize(width: maximumSize.width, height:UIViewNoIntrinsicMetric), apply: true)
        }
        preferredContentSize = CGSize(width: maximumSize.width, height: sizeThatFits.height)
        expandedArticleView.frame = CGRect(origin: .zero, size:preferredContentSize)
        view.layoutIfNeeded()
    }
    
    @available(iOSApplicationExtension 10.0, *)
    func widgetActiveDisplayModeDidChange(_ activeDisplayMode: NCWidgetDisplayMode, withMaximumSize maxSize: CGSize) {
        isExpanded = activeDisplayMode == .expanded
        updateView(maximumSize: maxSize, isExpanded: isExpanded)
    }
    
}
