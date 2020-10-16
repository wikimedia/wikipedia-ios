import UIKit

class ArticleAsLivingDocReferenceCollectionViewCell: ArticleAsLivingDocHorizontallyScrollingCell {
    
    private let titleLabel = UILabel()
    private var reference: ArticleAsLivingDocViewModel.Event.Large.Reference? = nil
    private var iconTitleBadge: IconTitleBadge?
    
    override func sizeThatFits(_ size: CGSize, apply: Bool) -> CGSize {
        
        guard apply else {
            return size
        }
        
        let adjustedMargins = ArticleAsLivingDocViewModel.Event.Large.sideScrollingCellPadding
        
        var availableTitleWidth = size.width - adjustedMargins.left - adjustedMargins.right
        let availableDescriptionWidth = availableTitleWidth
        
        if let iconTitleBadge = iconTitleBadge {
            let maximumBadgeWidth = min(size.width - adjustedMargins.right - adjustedMargins.left, size.width / 3)
            let iconBadgeOrigin = CGPoint(x: size.width - adjustedMargins.right, y: adjustedMargins.top)
            let iconBadgeFrame = iconTitleBadge.wmf_preferredFrame(at: iconBadgeOrigin, maximumWidth: maximumBadgeWidth, alignedBy: .forceLeftToRight, apply: false)
            let iconTitleBadgeX = size.width - adjustedMargins.right - iconBadgeFrame.width
                iconTitleBadge.frame = CGRect(x: iconTitleBadgeX, y: iconBadgeFrame.minY, width: iconBadgeFrame.width, height: iconBadgeFrame.height)
            let titleBadgeSpacing: CGFloat = 10
            availableTitleWidth -= iconBadgeFrame.width + titleBadgeSpacing
        }
        
        let titleOrigin = CGPoint(x: adjustedMargins.left, y: adjustedMargins.top)
        let titleFrame = titleLabel.wmf_preferredFrame(at: titleOrigin, maximumWidth: availableTitleWidth, alignedBy: .forceLeftToRight, apply: apply)
        
        let titleDescriptionSpacing = ArticleAsLivingDocViewModel.Event.Large.changeDetailReferenceTitleDescriptionSpacing
        let descriptionOrigin = CGPoint(x: adjustedMargins.left, y: titleFrame.maxY + titleDescriptionSpacing)
        
        descriptionTextView.wmf_preferredFrame(at: descriptionOrigin, maximumWidth: availableDescriptionWidth, alignedBy: .forceLeftToRight, apply: apply)
        
        layer.shadowPath = UIBezierPath(roundedRect: CGRect(origin: .zero, size: size), cornerRadius: backgroundView?.layer.cornerRadius ?? 0).cgPath
        
        return size
    }
    
    override func setup() {
        
        super.setup()
        descriptionTextView.textContainer.maximumNumberOfLines = 0
        contentView.addSubview(titleLabel)
        //adding icon badge in configure
    }
    
    override func reset() {
        super.reset()
        iconTitleBadge?.removeFromSuperview()
        iconTitleBadge = nil
        titleLabel.text = nil
    }
    
    private func createIconTitleBadgeForReference(reference: ArticleAsLivingDocViewModel.Event.Large.Reference) {
        guard let year = reference.accessDateYearDisplay else {
            return
        }
        
        let configuration = IconTitleBadge.Configuration(title: year, icon: .sfSymbol(name: "clock.fill"))
        let iconTitleBadge = IconTitleBadge(configuration: configuration, frame: .zero)
        contentView.addSubview(iconTitleBadge)
        self.iconTitleBadge = iconTitleBadge
    }
    
    override func configure(change: ArticleAsLivingDocViewModel.Event.Large.ChangeDetail, theme: Theme, delegate: ArticleAsLivingDocHorizontallyScrollingCellDelegate) {
        
        super.configure(change: change, theme: theme, delegate: delegate)
        
        switch change {
        case .reference(let reference):
            self.reference = reference
            createIconTitleBadgeForReference(reference: reference)
            titleLabel.text = reference.type
        default:
            assertionFailure("ArticleAsLivingDocReferenceCollectionViewCell configured with unexpected type")
            return
        }
        
        updateFonts(with: traitCollection)
        apply(theme: theme)
    }
    
    override func updateFonts(with traitCollection: UITraitCollection) {
        super.updateFonts(with: traitCollection)
        titleLabel.font = UIFont.wmf_font(ArticleAsLivingDocViewModel.Event.Large.changeDetailReferenceTitleStyle, compatibleWithTraitCollection: traitCollection)
        iconTitleBadge?.updateFonts(with: traitCollection)
    }
    
    override func apply(theme: Theme) {
        super.apply(theme: theme)
        titleLabel.textColor = theme.colors.secondaryText
        iconTitleBadge?.apply(theme: theme)
    }
}
