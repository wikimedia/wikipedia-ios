@objc class WMFUnconfiguredGradientView: UIView {
    public var gradientLayer: CAGradientLayer!
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
        gradientLayer = layer as! CAGradientLayer
        configureGradientLayer()
    }
    public func configureGradientLayer() {
        // override to configure gradientLayer.
    }
}
