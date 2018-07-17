import UIKit

class ImageCollectionViewCell: CollectionViewCell {
    let imageView: UIImageView = UIImageView()
    let gradientView: WMFGradientView = WMFGradientView()
    private let captionLabel: UILabel = UILabel()
    
    var caption: String? {
        get {
            return captionLabel.text
        }
        set {
            captionLabel.text = newValue
            setNeedsLayout()
        }
    }
    
    override func setup() {
        super.setup()
        if #available(iOS 11.0, *) {
            imageView.accessibilityIgnoresInvertColors = true
        }
        imageView.contentMode = .scaleAspectFill
        addSubview(imageView)
        gradientView.setStart(.clear, end: UIColor(white: 0, alpha: 0.8))
        addSubview(gradientView)
        captionLabel.numberOfLines = 3
        addSubview(captionLabel)
    }
    
    override func updateFonts(with traitCollection: UITraitCollection) {
        super.updateFonts(with: traitCollection)
        captionLabel.font = UIFont.wmf_font(.subheadline, compatibleWithTraitCollection: traitCollection)
    }
    
    override func reset() {
        super.reset()
        imageView.wmf_reset()
        captionLabel.text = nil
    }
    
    let ratio: CGFloat = 1.02
    
    override func sizeThatFits(_ size: CGSize, apply: Bool) -> CGSize {
        var size = super.sizeThatFits(size, apply: apply)
        if size.width != UIViewNoIntrinsicMetric {
            size.height = round(ratio * size.width)
        }else if size.height != UIViewNoIntrinsicMetric {
            size.width = round(size.height / ratio)
        }
        if apply {
            let boundsInsetByMargins = UIEdgeInsetsInsetRect(CGRect(origin: .zero, size: size), layoutMargins)
            imageView.frame = CGRect(origin: .zero, size: size)
            if captionLabel.wmf_hasAnyNonWhitespaceText {
                captionLabel.isHidden = false
                gradientView.isHidden = false
                var labelFrame = captionLabel.wmf_preferredFrame(at: boundsInsetByMargins.origin, maximumSize: boundsInsetByMargins.size, alignedBy: semanticContentAttribute, apply: false)
                labelFrame.origin = CGPoint(x: labelFrame.origin.x, y: size.height - labelFrame.height - layoutMargins.bottom)
                captionLabel.frame = labelFrame
                let gradientOriginY = labelFrame.minY - layoutMargins.bottom
                gradientView.frame = CGRect(x: 0, y: gradientOriginY, width: size.width, height: size.height - gradientOriginY)
            } else {
                captionLabel.isHidden = true
                gradientView.isHidden = true
            }
        }
        return size
    }
    

}

extension ImageCollectionViewCell: Themeable {
    func apply(theme: Theme) {
        setBackgroundColors(theme.colors.midBackground, selected: theme.colors.baseBackground)
        imageView.backgroundColor = .clear
        imageView.alpha = theme.imageOpacity
        captionLabel.textColor = .white
    }
}
