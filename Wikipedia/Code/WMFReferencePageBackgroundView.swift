
class WMFReferencePageBackgroundView: UIView, Themeable {
    var clearRect:CGRect = CGRect.zero {
        didSet {
            setNeedsDisplay()
        }
    }

    override func draw(_ rect: CGRect) {
        super.draw(rect)
        UIColor.clear.setFill()
        UIBezierPath.init(roundedRect: clearRect, cornerRadius: 3).fill(with: .copy, alpha: 1.0)
    }
    
    override func didMoveToSuperview() {
        isUserInteractionEnabled = false
        clearsContextBeforeDrawing = false
        translatesAutoresizingMaskIntoConstraints = false
    }
    
    var theme = Theme.standard
    
    func apply(theme: Theme) {
        self.theme = theme
        switch theme.name {
        case Theme.sepia.name:
            backgroundColor = UIColor.init(0x646059, alpha:0.6)
        case Theme.light.name:
            backgroundColor = UIColor.init(white: 0.0, alpha: 0.5)
        case Theme.darkDimmed.name:
            fallthrough
        case Theme.dark.name:
            backgroundColor = UIColor.init(white: 0.0, alpha: 0.75)
        default:
            break
        }
    }
}
