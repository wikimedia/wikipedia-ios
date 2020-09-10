

import UIKit

class SignificantEventsHeaderView: UIView {

    @IBOutlet private var headerLabel: UILabel!
    @IBOutlet private var titleLabel: UILabel!
    @IBOutlet private var summaryLabel: UILabel!
    @IBOutlet private var sparklineView: WMFSparklineView!
    @IBOutlet private var viewFullHistoryButton: ActionButton!
    @IBOutlet private var dividerView: UIView!
    
    private var editMetrics: [NSNumber]? {
        didSet {
            if shouldShowSparkline {
                sparklineView.isHidden = false
                sparklineView.dataValues = editMetrics ?? []
                sparklineView.updateMinAndMaxFromDataValues()
            } else {
                sparklineView.isHidden = true
            }
        }
    }
    
    private var shouldShowSparkline: Bool {
        guard let editMetrics = editMetrics,
              editMetrics.count > 0 else {
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
        
        viewFullHistoryButton.setTitle(WMFLocalizedString("significant-events-view-full-history-button", value: "View full article history", comment: "Text displayed in a button for pushing to the full article history view on the significant events screen."), for: .normal)
        viewFullHistoryButton.addTarget(self, action: #selector(tappedViewFullHistoryButton), for: .touchUpInside)
    }
    
    func configure(headerText: String, titleText: String?, summaryText: String?, editMetrics: [NSNumber]?, theme: Theme) {
        self.headerLabel.text = headerText
        if let titleText = titleText {
            self.titleLabel.text = titleText
        }
        
        if let summaryText = summaryText {
            self.summaryLabel.text = summaryText
        }
        
        self.editMetrics = editMetrics
        
        updateFonts(with: traitCollection)
    }
    
    // MARK - Dynamic Type
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
        guard contentSizeCategory == nil || contentSizeCategory != traitCollection.wmf_preferredContentSizeCategory else {
            return
        }
        contentSizeCategory = traitCollection.wmf_preferredContentSizeCategory
        updateFonts(with: traitCollection)
    }
    
    func updateFonts(with traitCollection: UITraitCollection) {
        headerLabel.font = UIFont.wmf_font(.semiboldSubheadline, compatibleWithTraitCollection: traitCollection)
        titleLabel.font = UIFont.wmf_font(.boldTitle1, compatibleWithTraitCollection: traitCollection)
        summaryLabel.font = UIFont.wmf_font(.semiboldSubheadline, compatibleWithTraitCollection: traitCollection)
        viewFullHistoryButton.updateFonts(with: traitCollection)
    }
    
    @objc func tappedViewFullHistoryButton() {
        print("tapped view full history button")
    }
}

extension SignificantEventsHeaderView {
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
