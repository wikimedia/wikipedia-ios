import UIKit

public class ExploreCardCollectionViewCell: CollectionViewCell {
    public let titleLabel = UILabel()
    public let subtitleLabel = UILabel()
    public let footerButton = AlignedImageButton()
    
    public override func setup() {
        super.setup()
        addSubview(titleLabel)
        addSubview(subtitleLabel)
        addSubview(footerButton)
    }
    
    var cardContentView: UIView? = nil {
        didSet {
            defer {
                setNeedsLayout()
            }
            oldValue?.removeFromSuperview()
            guard let view = cardContentView else {
                return
            }
            addSubview(view)
        }
    }
    
    override public func sizeThatFits(_ size: CGSize, apply: Bool) -> CGSize {
        let size = super.sizeThatFits(size, apply: apply) // intentionally shade size
        var origin = CGPoint(x: layoutMargins.left, y: layoutMargins.top)
        let widthMinusMargins = size.width - layoutMargins.left - layoutMargins.right
        let titleLabelFrame = titleLabel.wmf_preferredFrame(at: origin, fitting: widthMinusMargins, alignedBy: semanticContentAttribute, apply: apply)
        origin.y += titleLabelFrame.layoutHeight(with: 4)
        let subtitleLabelFrame = subtitleLabel.wmf_preferredFrame(at: origin, fitting: widthMinusMargins, alignedBy: semanticContentAttribute, apply: apply)
        origin.y += subtitleLabelFrame.layoutHeight(with: 8)
        
        if let cardContentView = cardContentView {
            let contentViewFrame = cardContentView.wmf_preferredFrame(at: origin, fitting: widthMinusMargins, alignedBy: semanticContentAttribute, apply: apply)
            origin.y += contentViewFrame.layoutHeight(with: 8)
        }
        
        let footerButtonFrame = footerButton.wmf_preferredFrame(at: origin, fitting: widthMinusMargins, alignedBy: semanticContentAttribute, apply: apply)
        origin.y += footerButtonFrame.layoutHeight(with: 8)
        
        return CGSize(width: size.width, height: origin.y)
    }
    
}
