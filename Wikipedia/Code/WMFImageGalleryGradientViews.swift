@objcMembers class WMFImageGalleryTopGradientView: WMFUnconfiguredGradientView {
    override public func configure() {
        backgroundColor = .clear
        gradientLayer.locations = [1.0, 0.0]
        gradientLayer.colors = [
            UIColor(white: 0, alpha: 0.35).cgColor,
            UIColor.clear.cgColor
        ]
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 1.0)
        gradientLayer.endPoint = CGPoint(x: 0.5, y: 0.0)
    }
}

@objcMembers class WMFImageGalleryBottomGradientView: WMFUnconfiguredGradientView {
    override public func configure() {
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
