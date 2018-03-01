
extension UITabBar {
    // Gross HAX: Get views we can overlay with badges.
    @objc public func wmf_badgeSuperviews() -> [UIView] {
        return subviews.filter{$0 is UIControl}.flatMap {
            $0.subviews.first(where: {$0 is UIImageView})
        }
    }
}

public class BadgeDotView: UIView, Themeable {
    fileprivate var theme: Theme = Theme.standard
    var dotColor: UIColor = .clear
    var outlineColor: UIColor = .clear
    required public init?(coder: NSCoder) {
        super.init(coder: coder)
        self.commonInit()
    }
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.commonInit()
    }
    fileprivate func commonInit() {
        clearsContextBeforeDrawing = false
        isOpaque = false
    }
    override public func draw(_ rect: CGRect) {
        let path = UIBezierPath(ovalIn: rect.insetBy(dx:4, dy:4))
        outlineColor.setStroke()
        dotColor.setFill()
        path.lineWidth = 4
        path.stroke()
        path.fill()
    }
    public func apply(theme: Theme) {
        self.theme = theme
        outlineColor = theme.colors.chromeBackground
        dotColor = theme.colors.accent
        if superview != nil {
            setNeedsDisplay()
            layoutIfNeeded()
        }
    }
}



