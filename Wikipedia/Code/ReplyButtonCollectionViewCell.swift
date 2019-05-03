
import UIKit

class ReplyButtonFooterView: SizeThatFitsReusableView {
    private let replyButton = ActionButton(frame: .zero)
    
    override func sizeThatFits(_ size: CGSize, apply: Bool) -> CGSize {
        let semanticContentAttribute: UISemanticContentAttribute = traitCollection.layoutDirection == .rightToLeft ? .forceRightToLeft : .forceLeftToRight
        
        let adjustedMargins = UIEdgeInsets(top: layoutMargins.top + 4, left: layoutMargins.left + 5, bottom: layoutMargins.bottom + 4, right: layoutMargins.right + 5)
        let maximumWidth = size.width - adjustedMargins.left - adjustedMargins.right
        let origin = CGPoint(x: adjustedMargins.left, y: adjustedMargins.top)
        
        let replyButtonFrame = wmf_preferredFrame(at: origin, maximumSize: CGSize(width: maximumWidth, height: UIView.noIntrinsicMetric), minimumSize: NoIntrinsicSize, alignedBy:semanticContentAttribute, apply: apply)
        
        let finalHeight = adjustedMargins.top + replyButtonFrame.height + adjustedMargins.bottom
        
        return CGSize(width: size.width, height: finalHeight)
    }
    
    override func updateFonts(with traitCollection: UITraitCollection) {
        replyButton.updateFonts(with: traitCollection)
    }
 
    override func setup() {
        
        replyButton.setTitle(WMFLocalizedString("talk-pages-reply-button-title", value: "Reply to this discussion", comment: "Text displayed in a reply button for replying to a talk page discussion thread."), for: .normal)
        addSubview(replyButton)
        super.setup()
    }
}

extension ReplyButtonFooterView: Themeable {
    func apply(theme: Theme) {
        backgroundColor = theme.colors.paperBackground
        replyButton.apply(theme: theme)
    }
}

