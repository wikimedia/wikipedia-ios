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

        collapsedArticleView.saveButton.addTarget(self, action: #selector(saveButtonPressed), for: .touchUpInside)
        collapsedArticleView.frame = view.bounds
        view.addSubview(collapsedArticleView)

        expandedArticleView.saveButton.addTarget(self, action: #selector(saveButtonPressed), for: .touchUpInside)
        expandedArticleView.frame = view.bounds
        view.addSubview(expandedArticleView)
        
        updateView()
        updateViewAlpha()
    }
    
    var isEmptyViewHidden = true
    
    var dataStore: MWKDataStore? {
        return SessionSingleton.sharedInstance()?.dataStore
    }
    
    var article: WMFArticle? {
        guard let featuredContentGroup = dataStore?.viewContext.newestGroup(of: .featuredArticle),
            let articleURL = featuredContentGroup.content?.first as? URL else {
                return nil
        }
        return dataStore?.fetchArticle(with: articleURL)
    }
    
    func widgetPerformUpdate(completionHandler: @escaping (NCUpdateResult) -> Void) {
        guard let article = self.article else {
                isEmptyViewHidden = false
                completionHandler(.failed)
                return
        }
        
        isEmptyViewHidden = true
        

        let theme:Theme
        
        if #available(iOSApplicationExtension 10.0, *) {
            theme = Theme.widget
        } else {
            theme = Theme.widgetiOS9
        }
        
        collapsedArticleView.configure(article: article, displayType: .relatedPages, index: 0, count: 1, shouldAdjustMargins: false, shouldShowSeparators: false, theme: theme, layoutOnly: false)
        collapsedArticleView.tintColor = theme.colors.link
        collapsedArticleView.saveButton.saveButtonState = article.savedDate == nil ? .longSave : .longSaved

        expandedArticleView.configure(article: article, displayType: .pageWithPreview, index: 0, count: 1, theme: theme, layoutOnly: false)
        expandedArticleView.tintColor = theme.colors.link
        expandedArticleView.saveButton.saveButtonState = article.savedDate == nil ? .longSave : .longSaved
        
        updateView()
        completionHandler(.newData)
    }
    
    func updateViewAlpha() {
        expandedArticleView.alpha = isExpanded ? 1 : 0
        collapsedArticleView.alpha =  isExpanded ? 0 : 1
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: { (context) in
            self.updateViewAlpha()
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
            expandedArticleView.frame = CGRect(origin: .zero, size:sizeThatFits)
        } else {
            collapsedArticleView.imageViewDimension = maximumSize.height - 30 //hax
            sizeThatFits = collapsedArticleView.sizeThatFits(CGSize(width: maximumSize.width, height:UIViewNoIntrinsicMetric), apply: true)
            collapsedArticleView.frame = CGRect(origin: .zero, size:sizeThatFits)
        }
        
        preferredContentSize = CGSize(width: maximumSize.width, height: sizeThatFits.height)
    }
    
    @available(iOSApplicationExtension 10.0, *)
    func widgetActiveDisplayModeDidChange(_ activeDisplayMode: NCWidgetDisplayMode, withMaximumSize maxSize: CGSize) {
        isExpanded = activeDisplayMode == .expanded
        updateView(maximumSize: maxSize, isExpanded: isExpanded)
    }
    
    func saveButtonPressed() {
        guard let article = self.article, let articleKey = article.key else {
            return
        }
        let isSaved = dataStore?.savedPageList.toggleSavedPage(forKey: articleKey) ?? false
        expandedArticleView.saveButton.saveButtonState = isSaved ? .longSaved : .longSave
        collapsedArticleView.saveButton.saveButtonState = isSaved ? .longSaved : .longSave
    }
    
}
