import UIKit

protocol OldTalkPageReplyCellDelegate: AnyObject {
    func tappedLink(_ url: URL, cell: OldTalkPageReplyCell, sourceView: UIView, sourceRect: CGRect?)
}

class OldTalkPageReplyCell: CollectionViewCell {
    
    weak var delegate: OldTalkPageReplyCellDelegate?
    
    private let titleTextView = UITextView()
    private let depthMarker = UIView()
    private var depth: UInt = 0
    
    private var theme: Theme?
    
    private var isDeviceRTL: Bool {
        return effectiveUserInterfaceLayoutDirection == .rightToLeft
    }
    
    var semanticContentAttributeOverride: UISemanticContentAttribute = .unspecified {
        didSet {
            textAlignmentOverride = semanticContentAttributeOverride == .forceRightToLeft ? NSTextAlignment.right : NSTextAlignment.left
            titleTextView.semanticContentAttribute = semanticContentAttributeOverride
        }
    }
    
    private var textAlignmentOverride: NSTextAlignment = .left {
        didSet {
            titleTextView.textAlignment = textAlignmentOverride
        }
    }
    
    override func sizeThatFits(_ size: CGSize, apply: Bool) -> CGSize {
        
        let isRTL = semanticContentAttributeOverride == .forceRightToLeft
        let adjustedMargins = UIEdgeInsets(top: layoutMargins.top, left: layoutMargins.left, bottom: 0, right: layoutMargins.right)
        
        var depthIndicatorOrigin: CGPoint?
        if depth > 0 {
            var depthIndicatorX = isRTL ? size.width - adjustedMargins.right : adjustedMargins.left
            
            let depthAdjustmentMultiplier = CGFloat(13) // todo: may want to shift this higher or lower depending on screen size. Also possibly give it a max value
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
        
        let titleTextViewFrame = titleTextView.wmf_preferredFrame(at: titleOrigin, maximumWidth: titleMaximumWidth, alignedBy: semanticContentAttributeOverride, apply: apply)
        
        let finalHeight = adjustedMargins.top + titleTextViewFrame.size.height + adjustedMargins.bottom
        
        if let depthIndicatorOrigin = depthIndicatorOrigin,
            apply {
            depthMarker.frame = CGRect(origin: depthIndicatorOrigin, size: CGSize(width: 2, height: titleTextViewFrame.height))
        }
        
        if apply {
            titleTextView.textAlignment = textAlignmentOverride
        }
        
        return CGSize(width: size.width, height: finalHeight)
    }
    
    func configure(title: String, depth: UInt) {
        self.depth = depth
        depthMarker.isHidden = depth < 1
        let attributedString = title.byAttributingHTML(with: .body, boldWeight: .semibold, matching: traitCollection, color: titleTextView.textColor, linkColor: theme?.colors.link, handlingLists: true, handlingSuperSubscripts: true)
        setupTitle(for: attributedString)
        setNeedsLayout()
    }
    
    override func reset() {
        super.reset()
        titleTextView.attributedText = nil
        depth = 0
        depthMarker.isHidden = true
        depthMarker.frame = .zero
    }
    
    private func setupTitle(for attributedText: NSAttributedString) {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 7
        let attrString = NSMutableAttributedString(attributedString: attributedText)
        attrString.addAttribute(NSAttributedString.Key.paragraphStyle, value:paragraphStyle, range:NSRange(location: 0, length: attrString.length))
        titleTextView.attributedText = attrString
    }
    
    override func updateFonts(with traitCollection: UITraitCollection) {
        super.updateFonts(with: traitCollection)
        setupTitle(for: titleTextView.attributedText)
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

// MARK: Themeable

extension OldTalkPageReplyCell: Themeable {
    func apply(theme: Theme) {
        self.theme = theme
        titleTextView.textColor = theme.colors.primaryText
        titleTextView.backgroundColor = theme.colors.paperBackground
        depthMarker.backgroundColor = .gray
        contentView.backgroundColor = theme.colors.paperBackground
    }
}

// MARK: UITextViewDelegate

extension OldTalkPageReplyCell: UITextViewDelegate {
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        delegate?.tappedLink(URL, cell: self, sourceView: textView, sourceRect: textView.frame(of: characterRange))
        return false
    }
}
