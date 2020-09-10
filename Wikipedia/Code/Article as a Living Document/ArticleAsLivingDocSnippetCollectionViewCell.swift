
import UIKit

class ArticleAsLivingDocSnippetCollectionViewCell: ArticleAsLivingDocHorizontallyScrollingCell {
    
    override func sizeThatFits(_ size: CGSize, apply: Bool) -> CGSize {
        
        let adjustedMargins = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)

        let descriptionX = adjustedMargins.left
        
        let descriptionOrigin = CGPoint(x: descriptionX, y: adjustedMargins.top)
        let descriptionMaximumWidth: CGFloat = (size.width - adjustedMargins.right) - descriptionOrigin.x
        
        let descriptionTextViewFrame = descriptionTextView.wmf_preferredFrame(at: descriptionOrigin, maximumWidth: descriptionMaximumWidth, alignedBy: .forceLeftToRight, apply: apply)
        
        let finalHeight = adjustedMargins.top + descriptionTextViewFrame.size.height + adjustedMargins.bottom
        
        let finalSize = CGSize(width: size.width, height: finalHeight)

        if (apply) {
            layer.shadowPath = UIBezierPath(roundedRect: CGRect(origin: .zero, size: finalSize), cornerRadius: backgroundView?.layer.cornerRadius ?? 0).cgPath
        }
        
        return finalSize
    }
}
