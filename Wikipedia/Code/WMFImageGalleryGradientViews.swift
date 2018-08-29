
@objcMembers class WMFImageGalleryBottomGradientView: SetupGradientView {
    override public func setup(gradientLayer: CAGradientLayer) {
        gradientLayer.locations = [0.0, 0.5, 1.0]
        gradientLayer.colors = [
            UIColor(white: 0, alpha: 1.0).cgColor,
            UIColor(white: 0, alpha: 0.5).cgColor,
            UIColor.clear.cgColor
        ]
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 1.0)
        gradientLayer.endPoint = CGPoint(x: 0.5, y: 0.0)
    }
}

class WMFImageGalleryDescriptionGradientView : UIView {
    private let fadeHeight = 6.0
    private var normalizedFadeHeight: Double {
        return bounds.size.height > 0 ? fadeHeight /  Double(bounds.size.height) : 0
    }
    
    private lazy var gradientMask: CAGradientLayer = {
        let mask = CAGradientLayer()
        mask.startPoint = .zero
        mask.endPoint = CGPoint(x: 0, y: 1)
        mask.colors = [
            UIColor.black.cgColor,
            UIColor.clear.cgColor,
            UIColor.clear.cgColor,
            UIColor.black.cgColor
        ]
        layer.backgroundColor = UIColor.black.cgColor
        layer.mask = mask
        return mask
    }()
    
    override func layoutSublayers(of layer: CALayer) {
        super.layoutSublayers(of: layer)
        guard layer == gradientMask.superlayer else {
            assertionFailure("Unexpected superlayer")
            return
        }
        gradientMask.locations = [  // Keep fade heights fixed to `fadeHeight` regardless of text view height
            0.0,
            NSNumber(value: normalizedFadeHeight),          // upper stop
            NSNumber(value: 1.0 - normalizedFadeHeight),    // lower stop
            1.0
        ]
        gradientMask.frame = bounds
    }
}
