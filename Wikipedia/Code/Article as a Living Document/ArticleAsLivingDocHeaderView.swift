import WMFComponents

class ArticleAsLivingDocHeaderView: UIView {

    @IBOutlet private var headerLabel: UILabel!
    @IBOutlet private var titleLabel: UILabel!
    @IBOutlet private var summaryLabel: UILabel!
    @IBOutlet private var sparklineView: WMFSparklineView!
    @IBOutlet var viewFullHistoryButton: ActionButton!
    @IBOutlet private var dividerView: UIView!
    @IBOutlet private var divHeightConstraint: NSLayoutConstraint!
    
    private var editMetrics: [NSNumber]? {
        didSet {
            if shouldShowSparkline {
                sparklineView.isHidden = false
                sparklineView.dataValues = editMetrics ?? []
            } else {
                sparklineView.isHidden = true
            }
        }
    }
    
    private var shouldShowSparkline: Bool {
        guard let editMetrics = editMetrics,
              editMetrics.count > 1 else {
            return false
        }
        
        return true
    }
    
    private var theme = Theme.standard
    
    override func awakeFromNib() {
        
        super.awakeFromNib()
        
        viewFullHistoryButton.titleLabelFont = .semiboldHeadline

        sparklineView.showsVerticalGridlines = true

        sparklineView.isAccessibilityElement = true
        sparklineView.accessibilityLabel = WMFLocalizedString("page-history-graph-accessibility-label", value: "Graph of edits over time", comment: "Accessibility label text used for edits graph")
        
        titleLabel.numberOfLines = 0
        summaryLabel.numberOfLines = 0
        
        viewFullHistoryButton.setTitle(CommonStrings.viewFullHistoryText, for: .normal)
        
        divHeightConstraint.constant = 1 / UIScreen.main.scale
    }
    
    func configure(headerText: String, titleText: String?, summaryText: String?, editMetrics: [NSNumber]?, theme: Theme) {
        self.headerLabel.text = headerText
        self.titleLabel.text = titleText
        self.summaryLabel.text = summaryText
        
        self.editMetrics = editMetrics
        
        updateFonts(with: traitCollection)
    }
    
    // MARK: - Dynamic Type
    // Only applies new fonts if the content size category changes
    
    open override func setNeedsLayout() {
        maybeUpdateFonts(with: traitCollection)
        super.setNeedsLayout()
    }
    
    override open func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        setNeedsLayout()
    }
    
    var contentSizeCategory: UIContentSizeCategory?
    fileprivate func maybeUpdateFonts(with traitCollection: UITraitCollection) {
        guard contentSizeCategory == nil || contentSizeCategory != traitCollection.preferredContentSizeCategory else {
            return
        }
        contentSizeCategory = traitCollection.preferredContentSizeCategory
        updateFonts(with: traitCollection)
    }
    
    func updateFonts(with traitCollection: UITraitCollection) {
        headerLabel.font = WMFFont.for(.mediumSubheadline, compatibleWith: traitCollection)
        titleLabel.font = WMFFont.for(.boldTitle1, compatibleWith: traitCollection)
        summaryLabel.font = WMFFont.for(.mediumSubheadline, compatibleWith: traitCollection)
        viewFullHistoryButton.updateFonts(with: traitCollection)
    }
}

extension ArticleAsLivingDocHeaderView {
    func apply(theme: Theme) {
        self.theme = theme
        backgroundColor = theme.colors.paperBackground
        headerLabel.textColor = theme.colors.secondaryText
        titleLabel.textColor = theme.colors.primaryText
        summaryLabel.textColor = theme.colors.accent
        sparklineView.apply(theme: theme)
        viewFullHistoryButton.apply(theme: theme)
        dividerView.backgroundColor = theme.colors.border
    }
}
