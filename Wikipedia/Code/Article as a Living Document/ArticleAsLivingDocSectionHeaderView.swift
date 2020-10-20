
import UIKit

class ArticleAsLivingDocSectionHeaderView: SizeThatFitsReusableView {
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private var theme: Theme?
    
    override func setup() {
        addSubview(titleLabel)
        titleLabel.numberOfLines = 1
        addSubview(subtitleLabel)
        subtitleLabel.numberOfLines = 1
        super.setup()
    }
    
    override func reset() {
        super.reset()
        titleLabel.text = nil
        subtitleLabel.text = nil
    }
    
    override func sizeThatFits(_ size: CGSize, apply: Bool) -> CGSize {
        let adjustedMargins = UIEdgeInsets(top: layoutMargins.top + 24, left: layoutMargins.left, bottom: layoutMargins.bottom + 12, right: layoutMargins.right)
        
        let maximumWidth = size.width - adjustedMargins.left - adjustedMargins.right
        
        let titleOrigin = CGPoint(x: adjustedMargins.left, y: adjustedMargins.top)
        let titleFrame = titleLabel.wmf_preferredFrame(at: titleOrigin, maximumSize: CGSize(width: maximumWidth, height: UIView.noIntrinsicMetric), minimumSize: NoIntrinsicSize, alignedBy: .forceLeftToRight, apply: apply)
        
        let titleSubtitleSpacing: CGFloat = 7
        let subtitleOrigin = CGPoint(x: adjustedMargins.left, y: titleFrame.maxY + titleSubtitleSpacing)
        let subtitleFrame = subtitleLabel.wmf_preferredFrame(at: subtitleOrigin, maximumSize: CGSize(width: maximumWidth, height: UIView.noIntrinsicMetric), minimumSize: NoIntrinsicSize, alignedBy: .forceLeftToRight, apply: apply)
        
        let finalHeight = subtitleFrame.maxY + adjustedMargins.bottom
        
        return CGSize(width: size.width, height: finalHeight)
    }
    
    func configure(viewModel: ArticleAsLivingDocViewModel.SectionHeader, theme: Theme) {
        
        self.titleLabel.text = viewModel.title
        self.subtitleLabel.text = viewModel.subtitleTimestampDisplay
        setNeedsLayout()
        
        apply(theme: theme)
    }
    
    override func updateFonts(with traitCollection: UITraitCollection) {
        super.updateFonts(with: traitCollection)
        titleLabel.font = UIFont.wmf_font(.semiboldSubheadline, compatibleWithTraitCollection: traitCollection)
        subtitleLabel.font = UIFont.wmf_font(.subheadline, compatibleWithTraitCollection: traitCollection)
        setNeedsLayout()
    }
}

extension ArticleAsLivingDocSectionHeaderView: Themeable {
    func apply(theme: Theme) {
        self.theme = theme
        titleLabel.textColor = theme.colors.primaryText
        subtitleLabel.textColor = theme.colors.secondaryText
    }
}
