import UIKit
import WMFComponents

class SuggestedEditsExploreCell: CollectionViewCell {
    
    private let titleLabel: UILabel = UILabel()
    private let bodyLabel: UILabel = UILabel()
    private let imageView: UIImageView? = {
        return UIImageView(image: WMFSFSymbolIcon.for(symbol: .addPhoto, font: WMFFont.title1))
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
    
    private var isRTL: Bool {
        return appLangSemanticContentAttribute == .forceRightToLeft
    }
    
    private var appLangSemanticContentAttribute: UISemanticContentAttribute {
        
        if let contentLanguageCode = MWKDataStore.shared().languageLinkController.appLanguage?.contentLanguageCode {
            let semanticContentAttribute = MWKLanguageLinkController.semanticContentAttribute(forContentLanguageCode: contentLanguageCode)
            return semanticContentAttribute
        }
        
        return semanticContentAttribute
    }
    
    override func setup() {
        super.setup()
        titleLabel.numberOfLines = 0
        titleLabel.textAlignment = isRTL ? .right : .left
        bodyLabel.numberOfLines = 0
        bodyLabel.textAlignment = isRTL ? .right : .left
        addSubview(titleLabel)
        addSubview(bodyLabel)
        
        if let imageView {
            imageView.contentMode = .scaleAspectFit
            addSubview(imageView)
        }
    }
    
    override func updateFonts(with traitCollection: UITraitCollection) {
        super.updateFonts(with: traitCollection)
        titleLabel.font = WMFFont.for(.callout, compatibleWith: traitCollection)
        bodyLabel.font = WMFFont.for(.subheadline, compatibleWith: traitCollection)
    }
    
    override func sizeThatFits(_ size: CGSize, apply: Bool) -> CGSize {
        
        layoutMarginsAdditions = UIEdgeInsets(top: 12, left: 0, bottom: 12, right: 0)
        
        let layoutMargins = calculatedLayoutMargins
        let maxImageWidth = CGFloat(100)
        
        let initialOrigin = CGPoint(x: layoutMargins.left, y: layoutMargins.top)
        
        let imageSize = imageView?.wmf_preferredFrame(at: initialOrigin, maximumWidth: maxImageWidth, alignedBy: .forceLeftToRight, apply: false).size ?? .zero
        
        let labelsImageSpacing = CGFloat(16)
        
        let labelWidthToFit = size.width - layoutMargins.right - layoutMargins.left - imageSize.width - labelsImageSpacing
        
        let titleWidth = titleLabel.wmf_preferredFrame(at: initialOrigin, maximumSize: CGSize(width: labelWidthToFit, height: UIView.noIntrinsicMetric), minimumSize: NoIntrinsicSize, alignedBy: .forceLeftToRight, apply: false).size.width
        let bodyWidth = bodyLabel.wmf_preferredFrame(at: initialOrigin, maximumSize: CGSize(width: labelWidthToFit, height: UIView.noIntrinsicMetric), minimumSize: NoIntrinsicSize, alignedBy: .forceLeftToRight, apply: false).size.width
 
        let titleOrigin = isRTL ? CGPoint(x: size.width - layoutMargins.right - titleWidth, y: initialOrigin.y) : initialOrigin
        
        let titleFrame = titleLabel.wmf_preferredFrame(at: titleOrigin, maximumSize: CGSize(width: labelWidthToFit, height: UIView.noIntrinsicMetric), minimumSize: NoIntrinsicSize, alignedBy: .forceLeftToRight, apply: apply)
        
        let titleBodySpacing = CGFloat(5)
        
        let bodyOrigin = isRTL ? CGPoint(x: size.width - layoutMargins.right - bodyWidth, y: titleFrame.maxY + titleBodySpacing) : CGPoint(x: initialOrigin.x, y: titleFrame.maxY + titleBodySpacing)
        
        let bodyFrame = bodyLabel.wmf_preferredFrame(at: bodyOrigin, maximumSize: CGSize(width: labelWidthToFit, height: UIView.noIntrinsicMetric), minimumSize: NoIntrinsicSize, alignedBy: .forceLeftToRight, apply: apply)
        
        let finalHeight = bodyFrame.maxY + layoutMargins.bottom
        
        let imageY = (finalHeight / 2) - (imageSize.height / 2)
        let imageX = isRTL ? initialOrigin.x : size.width - layoutMargins.right - imageSize.width

        imageView?.wmf_preferredFrame(at: CGPoint(x: imageX, y: imageY), maximumWidth: maxImageWidth, alignedBy: .forceLeftToRight, apply: true)
        
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
