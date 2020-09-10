
import UIKit

class SignificantEventsSectionHeaderView: SizeThatFitsReusableView {
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private var theme: Theme?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
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
        let adjustedMargins = UIEdgeInsets(top: layoutMargins.top, left: layoutMargins.left, bottom: layoutMargins.bottom, right: layoutMargins.right)
        
        let maximumWidth = size.width - adjustedMargins.left - adjustedMargins.right
        
        let titleOrigin = CGPoint(x: adjustedMargins.left, y: adjustedMargins.top)
        let titleFrame = titleLabel.wmf_preferredFrame(at: titleOrigin, maximumSize: CGSize(width: maximumWidth, height: UIView.noIntrinsicMetric), minimumSize: NoIntrinsicSize, alignedBy: .forceLeftToRight, apply: apply)
        
        let titleSubtitleSpacing = CGFloat(7)
        let subtitleOrigin = CGPoint(x: adjustedMargins.left, y: titleFrame.maxY + titleSubtitleSpacing)
        let subtitleFrame = subtitleLabel.wmf_preferredFrame(at: subtitleOrigin, maximumSize: CGSize(width: maximumWidth, height: UIView.noIntrinsicMetric), minimumSize: NoIntrinsicSize, alignedBy: .forceLeftToRight, apply: apply)
        
        let finalHeight = subtitleFrame.maxY + adjustedMargins.bottom
        
        return CGSize(width: size.width, height: finalHeight)
    }
    
    func configure(viewModel: SectionHeaderViewModel, theme: Theme) {
        
        self.titleLabel.text = viewModel.title
        self.subtitleLabel.text = viewModel.subtitleTimestampDisplay
        
        apply(theme: theme)
    }
    
    override func updateFonts(with traitCollection: UITraitCollection) {
        super.updateFonts(with: traitCollection)
        titleLabel.font = UIFont.wmf_font(.boldSubheadline, compatibleWithTraitCollection: traitCollection)
        subtitleLabel.font = UIFont.wmf_font(.subheadline, compatibleWithTraitCollection: traitCollection)
    }
}

extension SignificantEventsSectionHeaderView: Themeable {
    func apply(theme: Theme) {
        self.theme = theme
        titleLabel.textColor = theme.colors.primaryText
        subtitleLabel.textColor = theme.colors.secondaryText
    }
}
