
@objcMembers class SetupGradientView: SetupView {
    override class var layerClass: AnyClass {
        return CAGradientLayer.self
    }
    // Subclassers should override setup:gradientLayer: instead of any of the initializers. Subclassers must call super.setup()
    open func setup(gradientLayer: CAGradientLayer) {
        // override to configure gradientLayer and such.
    }
    final override func setup() {
        super.setup()
        setup(gradientLayer: layer as! CAGradientLayer)
    }
}
