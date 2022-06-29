class WMFReferencePageBackgroundView: UIView, Themeable {
    var referenceHighlightBackground: UIColor = .clear
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }

    func setup() {
        isUserInteractionEnabled = false
        clearsContextBeforeDrawing = false
        translatesAutoresizingMaskIntoConstraints = false
    }

    @objc var clearRect:CGRect = CGRect.zero {
        didSet {
            setNeedsDisplay()
        }
    }

    override func draw(_ rect: CGRect) {
        super.draw(rect)
        referenceHighlightBackground.setFill()
        UIBezierPath.init(roundedRect: clearRect, cornerRadius: 3).fill(with: .copy, alpha: 1.0)
    }

    
    func apply(theme: Theme) {
        backgroundColor = theme.colors.overlayBackground
        referenceHighlightBackground = theme.colors.referenceHighlightBackground
    }
}
