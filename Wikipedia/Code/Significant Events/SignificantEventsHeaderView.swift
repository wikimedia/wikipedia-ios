

import UIKit

class SignificantEventsHeaderView: SizeThatFitsReusableView {

    private let headerLabel = UILabel()
    private let titleLabel = UILabel()
    private let summaryLabel = UILabel()
    private let sparklineView = WMFSparklineView()
    private let viewFullHistoryButton = ActionButton(frame: .zero)
    let dividerView = UIView(frame: .zero)
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
    
    private var adjustedMargins: UIEdgeInsets {
        return UIEdgeInsets(top: layoutMargins.top + 14, left: layoutMargins.left - 5, bottom: layoutMargins.bottom, right: layoutMargins.right - 5)
    }
    
    override func setup() {
        
        addSubview(headerLabel)
        addSubview(titleLabel)
        addSubview(summaryLabel)
        addSubview(sparklineView)
        addSubview(viewFullHistoryButton)
        addSubview(dividerView)
        
        viewFullHistoryButton.titleLabelFont = .semiboldHeadline

        sparklineView.showsVerticalGridlines = true

        sparklineView.isAccessibilityElement = true
        sparklineView.accessibilityLabel = WMFLocalizedString("page-history-graph-accessibility-label", value: "Graph of edits over time", comment: "Accessibility label text used for edits graph")
        
        titleLabel.numberOfLines = 0
        summaryLabel.numberOfLines = 0
        
        viewFullHistoryButton.setTitle(WMFLocalizedString("significant-events-view-full-history-button", value: "View full article history", comment: "Text displayed in a button for pushing to the full article history view on the significant events screen."), for: .normal)
        viewFullHistoryButton.addTarget(self, action: #selector(tappedViewFullHistoryButton), for: .touchUpInside)

        super.setup()
    }
    
    override func sizeThatFits(_ size: CGSize, apply: Bool) -> CGSize {
        print("🎉\(layoutMargins)")
        let maximumWidth = size.width - adjustedMargins.left - adjustedMargins.right
        
        let headerOrigin = CGPoint(x: adjustedMargins.left, y: adjustedMargins.top)
        let headerFrame = headerLabel.wmf_preferredFrame(at: headerOrigin, maximumSize: CGSize(width: maximumWidth, height: UIView.noIntrinsicMetric), minimumSize: NoIntrinsicSize, alignedBy: .forceLeftToRight, apply: apply)
        
        let headerTitleSpacing = CGFloat(12)
        
        let sparklineToParentWidthRatio = 0.38133333
        let sparklineHeightToWidthRatio = 0.57343
        let sparklineWidth = Double(size.width) * sparklineToParentWidthRatio
        let sparklineHeight = sparklineWidth * sparklineHeightToWidthRatio
        let titleSparklineSpacing = Double(15)
        
        let availableTitleWidth = shouldShowSparkline ? Double(maximumWidth) - sparklineWidth - titleSparklineSpacing : Double(maximumWidth)
        
        let titleOrigin = CGPoint(x: adjustedMargins.left, y: headerFrame.maxY + headerTitleSpacing)
        
        let titleFrame = titleLabel.wmf_preferredFrame(at: titleOrigin, maximumSize: CGSize(width: CGFloat(availableTitleWidth), height: UIView.noIntrinsicMetric), minimumSize: NoIntrinsicSize, alignedBy: .forceLeftToRight, apply: apply)
        
        let sparklineX = size.width - adjustedMargins.right - CGFloat(sparklineWidth)
        let sparklineFrame: CGRect = CGRect(x: sparklineX, y: titleFrame.minY, width: CGFloat(sparklineWidth), height: CGFloat(sparklineHeight))
        
        if (apply && shouldShowSparkline) {
            sparklineView.frame = sparklineFrame
        }
        
        let titleSummarySpacing = CGFloat(16)
        
        let summaryMaxY = shouldShowSparkline ? max(sparklineFrame.maxY, titleFrame.maxY) : titleFrame.maxY
        
        let summaryOrigin = CGPoint(x: adjustedMargins.left, y: summaryMaxY + titleSummarySpacing)
        
        let summaryFrame = summaryLabel.wmf_preferredFrame(at: summaryOrigin, maximumSize: CGSize(width: CGFloat(maximumWidth), height: UIView.noIntrinsicMetric), minimumSize: NoIntrinsicSize, alignedBy: .forceLeftToRight, apply: apply)
        
        let summaryViewFullHistoryButtonSpacing = CGFloat(39)
        
        let viewFullHistoryOrigin = CGPoint(x: adjustedMargins.left, y: summaryFrame.maxY + summaryViewFullHistoryButtonSpacing)
        
        var viewFullHistoryFrame = viewFullHistoryButton.wmf_preferredFrame(at: viewFullHistoryOrigin, maximumSize: CGSize(width: maximumWidth, height: UIView.noIntrinsicMetric), minimumSize: CGSize(width: CGFloat(maximumWidth), height: UIView.noIntrinsicMetric), alignedBy:semanticContentAttribute, apply: apply)
        
        if (apply) {
            //update frame to be centered
            viewFullHistoryFrame.origin = CGPoint(x: (size.width / 2) - (viewFullHistoryFrame.width / 2), y: viewFullHistoryFrame.origin.y)
            viewFullHistoryButton.frame = viewFullHistoryFrame
        }
        
        let viewFullHistoryDividerSpacing = CGFloat(29)
        let divHeight = CGFloat(1)
        let divOrigin = CGPoint(x: 0, y: viewFullHistoryFrame.maxY + viewFullHistoryDividerSpacing)
        let dividerViewFrame = CGRect(x: divOrigin.x, y: divOrigin.y, width: size.width, height: divHeight)
        
        if (apply) {
            dividerView.frame = dividerViewFrame
        }
        
        let finalHeight = dividerViewFrame.maxY + adjustedMargins.bottom
        
        return CGSize(width: size.width, height: finalHeight)
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

    override func updateFonts(with traitCollection: UITraitCollection) {
        headerLabel.font = UIFont.wmf_font(.semiboldSubheadline, compatibleWithTraitCollection: traitCollection)
        titleLabel.font = UIFont.wmf_font(.boldTitle1, compatibleWithTraitCollection: traitCollection)
        summaryLabel.font = UIFont.wmf_font(.semiboldSubheadline, compatibleWithTraitCollection: traitCollection)
        viewFullHistoryButton.updateFonts(with: traitCollection)
        apply(theme: theme)
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
