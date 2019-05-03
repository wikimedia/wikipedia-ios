
import UIKit

class TalkPageHeaderView: SizeThatFitsReusableView {
    
    struct ViewModel {
        let header: String
        let title: String
        let info: String?
    }
    
    private let headerLabel = UILabel()
    private let titleLabel = UILabel()
    private let infoLabel = UILabel()
    private let dividerView = UIView(frame: .zero)
    
    private var viewModel: ViewModel?
    
    private var hasInfoText: Bool {
        return viewModel?.info != nil
    }
    
    override func setup() {
        super.setup()
        infoLabel.numberOfLines = 0
        titleLabel.numberOfLines = 0
        addSubview(headerLabel)
        addSubview(titleLabel)
        addSubview(dividerView)
    }
    
    override func sizeThatFits(_ size: CGSize, apply: Bool) -> CGSize {
        let adjustedMargins = UIEdgeInsets(top: layoutMargins.top, left: layoutMargins.left + 7, bottom: layoutMargins.bottom + 22, right: layoutMargins.right + 7)
        
        let talkOrigin = CGPoint(x: adjustedMargins.left, y: adjustedMargins.top)
        let labelMaximumWidth = size.width - adjustedMargins.left - adjustedMargins.right
        
        let semanticContentAttribute: UISemanticContentAttribute = traitCollection.layoutDirection == .rightToLeft ? .forceRightToLeft : .forceLeftToRight
        let headerFrame = headerLabel.wmf_preferredFrame(at: talkOrigin, maximumWidth: labelMaximumWidth, alignedBy: semanticContentAttribute, apply: apply)
        
        let titleOrigin = CGPoint(x: adjustedMargins.left, y: headerFrame.maxY + 15)
        let titleFrame = titleLabel.wmf_preferredFrame(at: titleOrigin, maximumWidth: labelMaximumWidth, alignedBy: semanticContentAttribute, apply: apply)
        
        var finalHeight: CGFloat
        if hasInfoText {
            let infoOrigin = CGPoint(x: adjustedMargins.left, y: titleFrame.maxY + 10)
            let infoFrame = infoLabel.wmf_preferredFrame(at: infoOrigin, maximumWidth: labelMaximumWidth, alignedBy: semanticContentAttribute, apply: apply)
            finalHeight = infoFrame.maxY + adjustedMargins.bottom
        } else {
            finalHeight = titleFrame.maxY + adjustedMargins.bottom
        }
        
        if (apply) {
            dividerView.frame = CGRect(x: 0, y: finalHeight - 1, width: size.width, height: 1)
        }
        
        return CGSize(width: size.width, height: finalHeight)
    }
    
    func configure(viewModel: ViewModel) {
        
        self.viewModel = viewModel
        
        if hasInfoText && infoLabel.superview == nil {
            addSubview(infoLabel)
            infoLabel.text = viewModel.info
        }
        
        headerLabel.text = viewModel.header
        
        //todo: we need to support discussion topic <b> <i> and <a> tags
        //also todo: need to add intro text truncated to 3 lines
        titleLabel.text = viewModel.title
        
        updateFonts(with: traitCollection)
    }
    
    override func updateFonts(with traitCollection: UITraitCollection) {
        super.updateFonts(with: traitCollection)
        headerLabel.font = UIFont.wmf_font(DynamicTextStyle.semiboldSubheadline, compatibleWithTraitCollection: traitCollection)
        titleLabel.font = UIFont.wmf_font(DynamicTextStyle.boldTitle2, compatibleWithTraitCollection: traitCollection)
        infoLabel.font = UIFont.wmf_font(DynamicTextStyle.footnote, compatibleWithTraitCollection: traitCollection)
    }
    
    
}

extension TalkPageHeaderView: Themeable {
    func apply(theme: Theme) {
        headerLabel.textColor = theme.colors.secondaryText
        titleLabel.textColor = theme.colors.primaryText
        infoLabel.textColor = theme.colors.secondaryText
        dividerView.backgroundColor = theme.colors.border
        backgroundColor = theme.colors.paperBackground
    }
}
