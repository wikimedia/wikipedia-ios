import UIKit

class ExploreCardCollectionViewCell: CollectionViewCell {
    let titleLabel = UILabel()
    let subtitleLabel = UILabel()
    let footerButton = AlignedImageButton()
    
    var contentViewController: UIViewController? = nil {
        didSet {
            
        }
    }
    
    override func sizeThatFits(_ size: CGSize, apply: Bool) -> CGSize {
        let size = super.sizeThatFits(size, apply: apply) // intentionally shade size
        var origin = CGPoint(x: layoutMargins.left, y: layoutMargins.top)
        let widthMinusMargins = size.width - layoutMargins.left - layoutMargins.right
        let titleLabelFrame = titleLabel.wmf_preferredFrame(at: origin, fitting: widthMinusMargins, alignedBy: semanticContentAttribute, apply: apply)
        origin.y += titleLabelFrame.layoutHeight(with: 4)
        let subtitleLabelFrame = subtitleLabel.wmf_preferredFrame(at: origin, fitting: widthMinusMargins, alignedBy: semanticContentAttribute, apply: apply)
        origin.y += subtitleLabelFrame.layoutHeight(with: 8)
        
        if let contentView = contentViewController?.view {
            let contentViewFrame = contentView.wmf_preferredFrame(at: origin, fitting: widthMinusMargins, alignedBy: semanticContentAttribute, apply: apply)
            origin.y += contentViewFrame.layoutHeight(with: 8)
        }
        
        let footerButtonFrame = footerButton.wmf_preferredFrame(at: origin, fitting: widthMinusMargins, alignedBy: semanticContentAttribute, apply: apply)
        origin.y += footerButtonFrame.layoutHeight(with: 8)
        
        return CGSize(width: size.width, height: origin.y)
    }
    
}
