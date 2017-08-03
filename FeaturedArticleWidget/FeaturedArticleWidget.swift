import UIKit
import NotificationCenter
import WMF

class FeaturedArticleWidget: UIViewController, NCWidgetProviding {
    let collapsedArticleView = ArticleRightAlignedImageCollectionViewCell()
    let expandedArticleView = ArticleFullWidthImageCollectionViewCell()

    var isExpanded = false
    var maximumSize = CGSize.zero
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        collapsedArticleView.frame = view.bounds
        view.addSubview(collapsedArticleView)

        expandedArticleView.frame = view.bounds
        view.addSubview(expandedArticleView)
        
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
        updateView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        view.addConstraints([expandedArticleView.topAnchor.constraint(equalTo: view.topAnchor), expandedArticleView.bottomAnchor.constraint(equalTo: view.bottomAnchor)])
    }
    
    var isEmptyViewHidden = true
    
    func updateView() {
        guard let session = SessionSingleton.sharedInstance(),
            let userStore = session.dataStore,
            let siteURL = MWKLanguageLinkController.sharedInstance().appLanguage?.siteURL(),
            let featuredContentGroup = userStore.viewContext.group(of: .featuredArticle, for: Date(), siteURL: siteURL),
            let articleURL = featuredContentGroup.content?.first as? URL,
            let article = userStore.fetchArticle(with: articleURL) else {
            isEmptyViewHidden = true
            return
        }
        
        //collapsedArticleView.configure(article: article, displayType: .page, index: 0, count: 1, theme: Theme.dark, layoutOnly: false)
        
        
        expandedArticleView.configure(article: article, displayType: featuredContentGroup.displayTypeForItem(at: 0), index: 0, count: 1, theme: Theme.dark, layoutOnly: false)
        preferredContentSize = expandedArticleView.sizeThatFits(CGSize(width: view.bounds.size.width, height: UIViewNoIntrinsicMetric), apply: true)
        //expandedArticleView.frame = CGRect(origin: .zero, size: preferredContentSize)
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
    }
    
    
    @available(iOSApplicationExtension 10.0, *)
    func widgetActiveDisplayModeDidChange(_ activeDisplayMode: NCWidgetDisplayMode, withMaximumSize maxSize: CGSize) {
        
    }
    
}
