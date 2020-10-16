
import UIKit

class ArticleAsLivingDocSmallEventCollectionViewCell: CollectionViewCell {
    private let descriptionTextView = UITextView()
    let timelineView = TimelineView()

    private var theme: Theme = Theme.standard
    
    private var smallEvent: ArticleAsLivingDocViewModel.Event.Small?

    weak var delegate: ArticleDetailsShowing?
    
    override func reset() {
        super.reset()
        descriptionTextView.attributedText = nil
    }
    
    override func setup() {
        super.setup()
        contentView.addSubview(descriptionTextView)
        timelineView.decoration = .squiggle
        descriptionTextView.isEditable = false
        descriptionTextView.isSelectable = false
        contentView.addSubview(timelineView)
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(tappedSmallChanges))
        descriptionTextView.addGestureRecognizer(tapGestureRecognizer)
    }
    
    override func sizeThatFits(_ size: CGSize, apply: Bool) -> CGSize {
        
        if (traitCollection.horizontalSizeClass == .compact) {
            layoutMarginsAdditions = UIEdgeInsets(top: 0, left: -5, bottom: 20, right: 0)
        } else {
            layoutMarginsAdditions = UIEdgeInsets(top: 0, left: 0, bottom: 20, right: 0)
        }
        
        let layoutMargins = calculatedLayoutMargins
        
        let timelineTextSpacing = CGFloat(5)
        let timelineWidth = CGFloat(15)
        let x = layoutMargins.left + timelineWidth + timelineTextSpacing
        let widthToFit = size.width - layoutMargins.right - x
        
        if apply {
            timelineView.frame = CGRect(x: layoutMargins.left, y: 0, width: timelineWidth, height: size.height)
        }
        
        let descriptionOrigin = CGPoint(x: x, y: layoutMargins.top)
        
        let descriptionFrame = descriptionTextView.wmf_preferredFrame(at: descriptionOrigin, maximumSize: CGSize(width: widthToFit, height: UIView.noIntrinsicMetric), minimumSize: NoIntrinsicSize, alignedBy: .forceLeftToRight, apply: apply)
        
        let finalHeight = descriptionFrame.maxY + layoutMargins.bottom
        
        return CGSize(width: size.width, height: finalHeight)
    }
    
    func configure(viewModel: ArticleAsLivingDocViewModel.Event.Small, theme: Theme) {
        
        self.smallEvent = viewModel
        
        descriptionTextView.attributedText = viewModel.eventDescriptionForTraitCollection(traitCollection, theme: theme)

        apply(theme: theme)
        setNeedsLayout()
    }
    
    override func layoutSublayers(of layer: CALayer) {
        super.layoutSublayers(of: layer)
        timelineView.dotsY = descriptionTextView.convert(descriptionTextView.bounds, to: timelineView).midY
    }
    
    override func updateFonts(with traitCollection: UITraitCollection) {
        super.updateFonts(with: traitCollection)
        if let smallEvent = smallEvent {
            descriptionTextView.attributedText = smallEvent.eventDescriptionForTraitCollection(traitCollection, theme: theme)
        }
    }
    
    @objc private func tappedSmallChanges() {
        guard let revisionID = smallEvent?.smallChanges.first?.revId else {
            return
        }
        delegate?.goToHistory(scrolledTo: Int(revisionID))
    }
}

extension ArticleAsLivingDocSmallEventCollectionViewCell: Themeable {
    func apply(theme: Theme) {
        self.theme = theme
        descriptionTextView.backgroundColor = theme.colors.paperBackground
        timelineView.backgroundColor = theme.colors.paperBackground
        timelineView.tintColor = theme.colors.accent
    }
}
