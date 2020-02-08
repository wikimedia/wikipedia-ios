import UIKit
import NotificationCenter
import WMF

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
    
    var dataStore: MWKDataStore? {
        return MWKDataStore.shared()
    }
    
    var article: WMFArticle? {
        guard
            let dataStore = dataStore,
            let featuredContentGroup = dataStore.viewContext.newestVisibleGroup(of: .featuredArticle) ?? dataStore.viewContext.newestGroup(of: .featuredArticle),
            let articleURL = featuredContentGroup.contentPreview as? URL else {
                return nil
        }
        return dataStore.fetchArticle(with: articleURL)
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
    
    func widgetPerformUpdate(completionHandler: @escaping (NCUpdateResult) -> Void) {
        defer {
            updateView()
        }
        guard let article = self.article,
            let articleKey = article.key else {
                isEmptyViewHidden = false
                completionHandler(.failed)
                return
        }
        
        guard articleKey != currentArticleKey else {
            completionHandler(.noData)
            return
        }
        
        currentArticleKey = articleKey
        isEmptyViewHidden = true
        
        collapsedArticleView.configure(article: article, displayType: .relatedPages, index: 0, shouldShowSeparators: false, theme: theme, layoutOnly: false)
        collapsedArticleView.titleTextStyle = .body
        collapsedArticleView.updateFonts(with: traitCollection)
        collapsedArticleView.tintColor = theme.colors.link

        expandedArticleView.configure(article: article, displayType: .pageWithPreview, index: 0, theme: theme, layoutOnly: false)
        expandedArticleView.tintColor = theme.colors.link
        expandedArticleView.saveButton.saveButtonState = article.savedDate == nil ? .longSave : .longSaved
        
        completionHandler(.newData)
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
        guard let article = self.article, let articleKey = article.key else {
            return
        }
        let isSaved = dataStore?.savedPageList.toggleSavedPage(forKey: articleKey) ?? false
        expandedArticleView.saveButton.saveButtonState = isSaved ? .longSaved : .longSave
    }

    @objc func handleTapGesture(_ tapGR: UITapGestureRecognizer) {
        guard tapGR.state == .recognized else {
            return
        }
        openApp(with: self.article?.url)
    }
}
