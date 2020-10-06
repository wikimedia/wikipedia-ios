
import UIKit

class ArticleAsLivingDocSnippetCollectionViewCell: ArticleAsLivingDocHorizontallyScrollingCell {
    
    override func sizeThatFits(_ size: CGSize, apply: Bool) -> CGSize {
        
        let adjustedMargins = ArticleAsLivingDocViewModel.Event.Large.padding

        let descriptionX = adjustedMargins.left
        
        let descriptionOrigin = CGPoint(x: descriptionX, y: adjustedMargins.top)
        let descriptionMaximumWidth: CGFloat = (size.width - adjustedMargins.right) - descriptionOrigin.x
        let descriptionMaximumHeight: CGFloat = size.height - adjustedMargins.top - adjustedMargins.bottom + 5 //little bit of padding needed here so snippets aren't inexplicably cut off
        
        let _ = descriptionTextView.wmf_preferredFrame(at: descriptionOrigin, maximumSize: CGSize(width: descriptionMaximumWidth, height: descriptionMaximumHeight), alignedBy: .forceLeftToRight, apply: apply)
        
        let finalSize = CGSize(width: size.width, height: size.height)

        if (apply) {
            layer.shadowPath = UIBezierPath(roundedRect: CGRect(origin: .zero, size: finalSize), cornerRadius: backgroundView?.layer.cornerRadius ?? 0).cgPath
        }
        
        return finalSize
    }
}
