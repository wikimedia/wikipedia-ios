import UIKit
import Components

class SuggestedEditsExploreCell: CollectionViewCell {
    
    private let titleLabel: UILabel = UILabel()
    private let bodyLabel: UILabel = UILabel()
    private let imageView: UIImageView? = {
        return UIImageView(image: WKSFSymbolIcon.for(symbol: .addPhoto, font: WKFont.title1))
    }()

    var title: String? {
        get {
            return titleLabel.text
        }
        set {
            titleLabel.text = newValue
            setNeedsLayout()
        }
    }
    
    var body: String? {
        get {
            return bodyLabel.text
        }
        set {
            bodyLabel.text = newValue
            setNeedsLayout()
        }
    }
    
    override func setup() {
        super.setup()
        titleLabel.numberOfLines = 0
        bodyLabel.numberOfLines = 0
        addSubview(titleLabel)
        addSubview(bodyLabel)
        if let imageView {
            imageView.contentMode = .scaleAspectFit
            addSubview(imageView)
        }
    }
    
    override func updateFonts(with traitCollection: UITraitCollection) {
        super.updateFonts(with: traitCollection)
        titleLabel.font = WKFont.for(.subheadline, compatibleWith: traitCollection)
        bodyLabel.font = WKFont.for(.subheadline, compatibleWith: traitCollection)
    }
    
    override func sizeThatFits(_ size: CGSize, apply: Bool) -> CGSize {
        
        layoutMarginsAdditions = UIEdgeInsets(top: 12, left: 0, bottom: 12, right: 0)
        
        let layoutMargins = calculatedLayoutMargins
        let maxImageWidth = CGFloat(100)
        
        let initialOrigin = CGPoint(x: layoutMargins.left, y: layoutMargins.top)
        
        let imageSize = imageView?.wmf_preferredFrame(at: initialOrigin, maximumWidth: maxImageWidth, alignedBy: semanticContentAttribute, apply: false).size ?? .zero
        
        let labelsImageSpacing = CGFloat(16)
        
        let labelWidthToFit = size.width - layoutMargins.right - layoutMargins.left - imageSize.width - labelsImageSpacing
 
        let titleFrame = titleLabel.wmf_preferredFrame(at: initialOrigin, maximumSize: CGSize(width: labelWidthToFit, height: UIView.noIntrinsicMetric), minimumSize: NoIntrinsicSize, alignedBy: semanticContentAttribute, apply: apply)
        
        let titleBodySpacing = CGFloat(5)
        let bodyOrigin = CGPoint(x: initialOrigin.x, y: titleFrame.maxY + titleBodySpacing)
        
        let bodyFrame = bodyLabel.wmf_preferredFrame(at: bodyOrigin, maximumSize: CGSize(width: labelWidthToFit, height: UIView.noIntrinsicMetric), minimumSize: NoIntrinsicSize, alignedBy: semanticContentAttribute, apply: apply)
        
        let finalHeight = bodyFrame.maxY + layoutMargins.bottom
        
        let imageY = (finalHeight / 2) - (imageSize.height / 2)
        let imageX = size.width - imageSize.width - layoutMargins.right
        
        imageView?.wmf_preferredFrame(at: CGPoint(x: imageX, y: imageY), maximumWidth: maxImageWidth, alignedBy: semanticContentAttribute, apply: true)
        
        return CGSize(width: size.width, height: finalHeight)
    }
}

extension SuggestedEditsExploreCell: Themeable {
    func apply(theme: Theme) {
        titleLabel.textColor = theme.colors.primaryText
        bodyLabel.textColor = theme.colors.secondaryText
        imageView?.tintColor = theme.colors.link
    }
}
