
import UIKit

protocol ReplyListItemCollectionViewCellDelegate: class {
    func tappedLink(_ url: URL, cell: ReplyListItemCollectionViewCell)
}

class ReplyListItemCollectionViewCell: CollectionViewCell {
    private let titleTextView = UITextView()
    private let depthMarker = UIView()
    weak var delegate: ReplyListItemCollectionViewCellDelegate?
    private var theme: Theme?
    
    private var depth: UInt = 0
    
    override func sizeThatFits(_ size: CGSize, apply: Bool) -> CGSize {
        
        let semanticContentAttribute: UISemanticContentAttribute = traitCollection.layoutDirection == .rightToLeft ? .forceRightToLeft : .forceLeftToRight
        let isRTL = semanticContentAttribute == .forceRightToLeft
        let adjustedMargins = UIEdgeInsets(top: layoutMargins.top + 4, left: layoutMargins.left + 5, bottom: layoutMargins.bottom + 4, right: layoutMargins.right + 5)
        
        var depthIndicatorOrigin: CGPoint?
        if depth > 0 {
            var depthIndicatorX = isRTL ? size.width - adjustedMargins.right : adjustedMargins.left
            
            let depthAdjustmentMultiplier = CGFloat(12) //todo: may want to shift this higher or lower depending on screen size. Also possibly give it a max value
            if isRTL {
                depthIndicatorX -= (CGFloat(depth) - 1) * depthAdjustmentMultiplier
            } else {
                depthIndicatorX += (CGFloat(depth) - 1) * depthAdjustmentMultiplier
            }
            
            depthIndicatorOrigin = CGPoint(x: depthIndicatorX, y: adjustedMargins.top)
        }

        var titleX: CGFloat
        if isRTL {
            titleX = adjustedMargins.left
        } else {
            titleX = depthIndicatorOrigin == nil ? adjustedMargins.left : depthIndicatorOrigin!.x + 10
        }
        
        let titleOrigin = CGPoint(x: titleX, y: adjustedMargins.top)
        var titleMaximumWidth: CGFloat
        if isRTL {
            titleMaximumWidth = depthIndicatorOrigin == nil ? size.width - adjustedMargins.right - titleOrigin.x : depthIndicatorOrigin!.x - adjustedMargins.left
        } else {
            titleMaximumWidth = (size.width - adjustedMargins.right) - titleOrigin.x
        }
        
        let titleTextViewFrame = titleTextView.wmf_preferredFrame(at: titleOrigin, maximumWidth: titleMaximumWidth, alignedBy: semanticContentAttribute, apply: apply)
        let finalHeight = adjustedMargins.top + titleTextViewFrame.size.height + adjustedMargins.bottom
        
        if let depthIndicatorOrigin = depthIndicatorOrigin,
            apply {
            depthMarker.frame = CGRect(origin: depthIndicatorOrigin, size: CGSize(width: 2, height: titleTextViewFrame.height))
        }
        
        return CGSize(width: size.width, height: finalHeight)
    }
    
    func configure(title: String, depth: UInt) {
        
        self.depth = depth
        depthMarker.isHidden = depth < 1
        
        let font = UIFont.wmf_font(.body, compatibleWithTraitCollection: traitCollection)
        let boldFont = UIFont.wmf_font(.semiboldBody, compatibleWithTraitCollection: traitCollection)
        
        let attributedString = title.wmf_attributedStringFromHTML(with: font, boldFont: boldFont, italicFont: font, boldItalicFont: boldFont, color: titleTextView.textColor, linkColor:theme?.colors.link, withAdditionalBoldingForMatchingSubstring:nil, tagMapping: nil, additionalTagAttributes: nil).wmf_trim()
        titleTextView.attributedText = attributedString
        setNeedsLayout()
    }
    
    override func reset() {
        super.reset()
        titleTextView.attributedText = nil
        depth = 0
        depthMarker.isHidden = true
        depthMarker.frame = .zero
    }
    
    override func updateFonts(with traitCollection: UITraitCollection) {
        super.updateFonts(with: traitCollection)
        titleTextView.font = UIFont.wmf_font(.body, compatibleWithTraitCollection: traitCollection)
    }
    
    override func setup() {
        titleTextView.isEditable = false
        titleTextView.isScrollEnabled = false
        titleTextView.delegate = self
        contentView.addSubview(titleTextView)
        contentView.addSubview(depthMarker)
        super.setup()
    }
}

extension ReplyListItemCollectionViewCell: Themeable {
    func apply(theme: Theme) {
        self.theme = theme
        titleTextView.textColor = theme.colors.primaryText
        titleTextView.backgroundColor = theme.colors.paperBackground
        depthMarker.backgroundColor = theme.colors.border
        contentView.backgroundColor = theme.colors.paperBackground
    }
}

extension ReplyListItemCollectionViewCell: UITextViewDelegate {
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        delegate?.tappedLink(URL, cell: self)
        return false
    }
}
