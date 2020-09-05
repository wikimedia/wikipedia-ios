

import UIKit

class SignificantEventsHeaderView: UIView {

    @IBOutlet var headerLabel: UILabel!
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var summaryLabel: UILabel!
    @IBOutlet var sparklineView: WMFSparklineView!
    
    private var theme = Theme.standard
    
    override func awakeFromNib() {
        sparklineView.showsVerticalGridlines = true

        sparklineView.isAccessibilityElement = true
        sparklineView.accessibilityLabel = WMFLocalizedString("page-history-graph-accessibility-label", value: "Graph of edits over time", comment: "Accessibility label text used for edits graph")
    }
    
    func configure(headerText: String, titleText: String?, summaryText: String?, theme: Theme) {
        self.headerLabel.text = headerText
        if let titleText = titleText {
            self.titleLabel.text = titleText
        }
        
        if let summaryText = summaryText {
            self.summaryLabel.text = summaryText
        }
        
        updateFonts()
    }

    private func updateFonts() {
        headerLabel.font = UIFont.wmf_font(.semiboldSubheadline, compatibleWithTraitCollection: traitCollection)
        titleLabel.font = UIFont.wmf_font(.boldTitle1, compatibleWithTraitCollection: traitCollection)
        summaryLabel.font = UIFont.wmf_font(.subheadline, compatibleWithTraitCollection: traitCollection)
        apply(theme: theme)
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
    }
}
