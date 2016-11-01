
class WMFReferencePageBackgroundView: UIView {
    var clearRect:CGRect = CGRectZero {
        didSet {
            setNeedsDisplay()
        }
    }

    override func drawRect(rect: CGRect) {
        super.drawRect(rect)
        UIColor.clearColor().setFill()
        UIBezierPath.init(roundedRect: clearRect, cornerRadius: 3).fillWithBlendMode(.Copy, alpha: 1.0)
    }
    
    override func didMoveToSuperview() {
        userInteractionEnabled = false
        clearsContextBeforeDrawing = false
        backgroundColor = UIColor.init(white: 0.0, alpha: 0.5)
        translatesAutoresizingMaskIntoConstraints = false
    }
}
