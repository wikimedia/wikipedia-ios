import Foundation

class ScrollViewGradientView : UIView, Themeable {
    private var theme = Theme.standard
    func apply(theme: Theme) {
        self.theme = theme
        layer.backgroundColor = theme.colors.midBackground.cgColor
    }
    
    var fadeHeight = 6.0
    var fadeTop = true
    private var normalizedFadeHeight: Double {
        return bounds.size.height > 0 ? fadeHeight /  Double(bounds.size.height) : 0
    }
    
    private lazy var gradientMask: CAGradientLayer = {
        let mask = CAGradientLayer()
        mask.startPoint = .zero
        mask.endPoint = CGPoint(x: 0, y: 1)
        if fadeTop {
            mask.colors = [
                UIColor.black.cgColor,
                UIColor.clear.cgColor,
                UIColor.clear.cgColor,
                UIColor.black.cgColor
            ]
        } else {
            mask.colors = [
                UIColor.clear.cgColor,
                UIColor.clear.cgColor,
                UIColor.clear.cgColor,
                UIColor.black.cgColor
            ]
        }
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
