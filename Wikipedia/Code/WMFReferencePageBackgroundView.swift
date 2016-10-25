
class WMFReferencePageBackgroundView: UIView {
    internal var clearRect:CGRect? = CGRectZero
    override func drawRect(rect: CGRect) {
        super.drawRect(rect)
        if let clearRect = clearRect {
            UIColor.clearColor().setFill()
            UIBezierPath.init(roundedRect: clearRect, cornerRadius: 3).fillWithBlendMode(.Copy, alpha: 1.0)
        }
    }
    
    override func didMoveToSuperview() {
        userInteractionEnabled = false
        clearsContextBeforeDrawing = false
        backgroundColor = UIColor.init(white: 0.0, alpha: 0.5)
        translatesAutoresizingMaskIntoConstraints = false
    }
}
