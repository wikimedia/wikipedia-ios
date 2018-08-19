@objcMembers class WMFUnconfiguredGradientView: UIView {
    override class var layerClass: AnyClass {
        return CAGradientLayer.self
    }
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    private func setup() {
        configure(gradientLayer: layer as! CAGradientLayer)
    }
    public func configure(gradientLayer: CAGradientLayer) {
        // override to configure gradientLayer and such.
    }
}
