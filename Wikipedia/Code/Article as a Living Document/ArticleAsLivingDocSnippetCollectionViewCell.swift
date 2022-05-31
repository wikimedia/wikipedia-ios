import UIKit

class ArticleAsLivingDocSnippetCollectionViewCell: ArticleAsLivingDocHorizontallyScrollingCell {
    
    override func sizeThatFits(_ size: CGSize, apply: Bool) -> CGSize {
        
        guard apply else {
            return size
        }
        
        let adjustedMargins = ArticleAsLivingDocViewModel.Event.Large.sideScrollingCellPadding
        
        let descriptionOrigin = CGPoint(x: adjustedMargins.left, y: adjustedMargins.top)
        let descriptionMaximumWidth: CGFloat = (size.width - adjustedMargins.right) - descriptionOrigin.x
        let descriptionMaximumHeight: CGFloat = size.height - adjustedMargins.top - adjustedMargins.bottom + 5 // little bit of extra space needed for snippet height here so snippets aren't inexplicably cut off.
        
        descriptionTextView.wmf_preferredFrame(at: descriptionOrigin, maximumSize: CGSize(width: descriptionMaximumWidth, height: descriptionMaximumHeight), alignedBy: .forceLeftToRight, apply: apply)
        
        layer.shadowPath = UIBezierPath(roundedRect: CGRect(origin: .zero, size: size), cornerRadius: backgroundView?.layer.cornerRadius ?? 0).cgPath
        
        return size
    }
}
