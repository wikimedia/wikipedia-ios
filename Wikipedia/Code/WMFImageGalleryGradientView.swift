@objc class WMFImageGalleryGradientView: WMFUnconfiguredGradientView {
    override public func configureGradientLayer() {
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
