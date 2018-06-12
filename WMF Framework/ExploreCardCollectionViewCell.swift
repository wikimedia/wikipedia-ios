import UIKit

public protocol CardContent {
    var view: UIView! { get }
    func sizeThatFits(_ size: CGSize, apply: Bool) -> CGSize
}
    
public class ExploreCardCollectionViewCell: CollectionViewCell {
    public let titleLabel = UILabel()
    public let subtitleLabel = UILabel()
    public let customizationButton = UIButton()
    public let footerButton = AlignedImageButton()
    
    public override func setup() {
        super.setup()
        contentView.addSubview(titleLabel)
        contentView.addSubview(subtitleLabel)
        customizationButton.setTitle(":", for: UIControlState.normal)
        contentView.addSubview(customizationButton)
        contentView.addSubview(footerButton)
    }
    
    public var cardContent: CardContent? = nil {
        didSet {
            defer {
                setNeedsLayout()
            }
            oldValue?.view?.removeFromSuperview()
            guard let view = cardContent?.view else {
                return
            }
            view.removeFromSuperview()
            view.isHidden = false
            view.autoresizingMask = []
            view.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview(view)
        }
    }
    
    override public func sizeThatFits(_ size: CGSize, apply: Bool) -> CGSize {
        let size = super.sizeThatFits(size, apply: apply) // intentionally shade size
        var origin = CGPoint(x: layoutMargins.left, y: layoutMargins.top)
        let widthMinusMargins = size.width - layoutMargins.left - layoutMargins.right
        let isRTL = semanticContentAttribute == .forceRightToLeft

        var customizationButtonSize = CGSize.zero
        if !customizationButton.isHidden {
            customizationButtonSize = customizationButton.sizeThatFits(CGSize(width: widthMinusMargins, height: UIViewNoIntrinsicMetric))
            var x = layoutMargins.right
            if !isRTL {
                x = size.width - x - customizationButtonSize.width
            }
            if apply {
                customizationButton.frame = CGRect(origin: CGPoint(x: x, y: origin.y), size: customizationButtonSize)
            }
        }
        
        let titleLabelFrame = titleLabel.wmf_preferredFrame(at: origin, fitting: widthMinusMargins - customizationButtonSize.width, alignedBy: semanticContentAttribute, apply: apply)
        origin.y += titleLabelFrame.layoutHeight(with: 4)
        let subtitleLabelFrame = subtitleLabel.wmf_preferredFrame(at: origin, fitting: widthMinusMargins - customizationButtonSize.width, alignedBy: semanticContentAttribute, apply: apply)
        origin.y += subtitleLabelFrame.layoutHeight(with: 8)
        
        if let cardContent = cardContent, let cardContentView = cardContent.view {
            let cardContentViewSize = cardContent.sizeThatFits(CGSize(width: widthMinusMargins, height: UIViewNoIntrinsicMetric), apply: apply)
            let cardContentViewFrame = CGRect(origin: origin, size: cardContentViewSize)
            if apply {
                cardContentView.frame = cardContentViewFrame
            }
            origin.y += cardContentViewFrame.layoutHeight(with: 8)
        }
        
        let footerButtonFrame = footerButton.wmf_preferredFrame(at: origin, fitting: widthMinusMargins, alignedBy: semanticContentAttribute, apply: apply)
        origin.y += footerButtonFrame.layoutHeight(with: 8)
        
        return CGSize(width: size.width, height: origin.y)
    }
    
}
