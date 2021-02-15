import UIKit
import NotificationCenter
import WMF
import CocoaLumberjackSwift

private final class EmptyView: SetupView, Themeable {
    private let label = UILabel()

    func apply(theme: Theme) {
        label.textColor = theme.colors.primaryText
    }

    override func setup() {
        super.setup()
        label.text = WMFLocalizedString("featured-article-empty-title", value: "No featured article available today", comment: "Title that displays when featured article is not available")
        label.textAlignment = .center
        label.numberOfLines = 0
        updateFonts()
        wmf_addSubviewWithConstraintsToEdges(label)
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        updateFonts()
    }

    private func updateFonts() {
        label.font = UIFont.wmf_font(.headline, compatibleWithTraitCollection: traitCollection)
    }
}

class FeaturedArticleWidget: ExtensionViewController, NCWidgetProviding {
    let collapsedArticleView = ArticleRightAlignedImageCollectionViewCell()
    let expandedArticleView = ArticleFullWidthImageCollectionViewCell()

    var isExpanded = true
    
    var currentArticleKey: String?

    private lazy var emptyView = EmptyView()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        view.translatesAutoresizingMaskIntoConstraints = false

        let tapGR = UITapGestureRecognizer(target: self, action: #selector(handleTapGesture(_:)))
        view.addGestureRecognizer(tapGR)

        collapsedArticleView.preservesSuperviewLayoutMargins = true
        collapsedArticleView.frame = view.bounds
        view.addSubview(collapsedArticleView)

        expandedArticleView.preservesSuperviewLayoutMargins = true
        expandedArticleView.saveButton.addTarget(self, action: #selector(saveButtonPressed), for: .touchUpInside)
        expandedArticleView.frame = view.bounds
        
        view.addSubview(expandedArticleView)

        view.wmf_addSubviewWithConstraintsToEdges(emptyView)
    }
    
    
    var isEmptyViewHidden = true {
        didSet {
            extensionContext?.widgetLargestAvailableDisplayMode = isEmptyViewHidden ? .expanded : .compact
            emptyView.isHidden = isEmptyViewHidden
            collapsedArticleView.isHidden = !isEmptyViewHidden
            expandedArticleView.isHidden = !isEmptyViewHidden
        }
    }
    
    override func apply(theme: Theme) {
        super.apply(theme: theme)
        guard viewIfLoaded != nil else {
            return
        }
        emptyView.apply(theme: theme)
        collapsedArticleView.apply(theme: theme)
        collapsedArticleView.tintColor = theme.colors.link
        expandedArticleView.apply(theme: theme)
        expandedArticleView.tintColor = theme.colors.link
    }
    
    var articleURL: URL?
    
    func widgetPerformUpdate(completionHandler: @escaping (NCUpdateResult) -> Void) {
        WidgetController.shared.startWidgetUpdateTask(completionHandler) { (dataStore, completion) in
            let moc = dataStore.viewContext
            let siteURL = dataStore.primarySiteURL
            moc.perform {
                guard let featuredContentGroup = moc.newestGroup(of: .featuredArticle, forSiteURL: siteURL),
                    let articleURL = featuredContentGroup.contentPreview as? URL else {
                    completion(.noData)
                    return
                }
                let article = moc.fetchArticle(with: articleURL)
                self.update(with: article, dataStore: dataStore) { result in
                    completion(result ? .newData : .noData)
                }
            }
        }
    }
    
    func update(with article: WMFArticle?, dataStore: MWKDataStore, completion: ((Bool) -> Void)?  = nil) {
        collapsedArticleView.imageView.wmf_imageController = dataStore.cacheController
        expandedArticleView.imageView.wmf_imageController = dataStore.cacheController
        articleURL = article?.url
        guard let article = article,
            let articleKey = article.key else {
                isEmptyViewHidden = false
                completion?(false)
                return
        }
        
        guard articleKey != currentArticleKey else {
            completion?(false)
            return
        }
        
        currentArticleKey = articleKey
        isEmptyViewHidden = true
        
        let group = DispatchGroup()
        group.enter()
        collapsedArticleView.configure(article: article, displayType: .relatedPages, index: 0, shouldShowSeparators: false, theme: theme, layoutOnly: false) {
            group.leave()
        }
        collapsedArticleView.titleTextStyle = .body
        collapsedArticleView.updateFonts(with: traitCollection)
        collapsedArticleView.tintColor = theme.colors.link

        group.enter()
        expandedArticleView.configure(article: article, displayType: .pageWithPreview, index: 0, theme: theme, layoutOnly: false) {
            group.leave()
        }
        expandedArticleView.tintColor = theme.colors.link
        expandedArticleView.saveButton.saveButtonState = article.isAnyVariantSaved ? .longSaved : .longSave
        updateView()
        
        group.notify(queue: .main) {
            completion?(true)
        }
    }
    
    func updateViewAlpha(isExpanded: Bool) {
        expandedArticleView.alpha = isExpanded ? 1 : 0
        collapsedArticleView.alpha =  isExpanded ? 0 : 1
    }

    @objc func updateView() {
        guard viewIfLoaded != nil else {
            return
        }
        var maximumSize = CGSize(width: view.bounds.size.width, height: UIView.noIntrinsicMetric)
        if let context = extensionContext {
            isExpanded = context.widgetActiveDisplayMode == .expanded
            maximumSize = context.widgetMaximumSize(for: context.widgetActiveDisplayMode)
        }
        updateViewAlpha(isExpanded: isExpanded)
        updateViewWithMaximumSize(maximumSize, isExpanded: isExpanded)
    }
    
    func updateViewWithMaximumSize(_ maximumSize: CGSize, isExpanded: Bool) {
        let sizeThatFits: CGSize
        if isExpanded {
            sizeThatFits = expandedArticleView.sizeThatFits(CGSize(width: maximumSize.width, height:UIView.noIntrinsicMetric), apply: true)
            expandedArticleView.frame = CGRect(origin: .zero, size:sizeThatFits)
        } else {
            collapsedArticleView.imageViewDimension = maximumSize.height - 30 //hax
            sizeThatFits = collapsedArticleView.sizeThatFits(CGSize(width: maximumSize.width, height:UIView.noIntrinsicMetric), apply: true)
            collapsedArticleView.frame = CGRect(origin: .zero, size:sizeThatFits)
        }
        preferredContentSize = CGSize(width: maximumSize.width, height: sizeThatFits.height)
    }
    
    func widgetActiveDisplayModeDidChange(_ activeDisplayMode: NCWidgetDisplayMode, withMaximumSize maxSize: CGSize) {
        debounceViewUpdate()
    }

    func debounceViewUpdate() {
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(updateView), object: nil)
        perform(#selector(updateView), with: nil, afterDelay: 0.1)
    }
    
    @objc func saveButtonPressed() {
        guard let articleKey = articleURL?.wmf_databaseKey else {
            return
        }
        WidgetController.shared.startWidgetUpdateTask { (done: Bool) in
            DDLogDebug("Widget did finish: \(done)")
        } _: { (dataStore, completion) in
            dataStore.viewContext.perform {
                let isSaved = dataStore.savedPageList.toggleSavedPage(forKey: articleKey, variant: self.articleURL?.wmf_languageVariantCode)
                self.expandedArticleView.saveButton.saveButtonState = isSaved ? .longSaved : .longSave
                completion(isSaved)
            }
        }
    }

    @objc func handleTapGesture(_ tapGR: UITapGestureRecognizer) {
        guard tapGR.state == .recognized else {
            return
        }
        openApp(with: articleURL)
    }
}
