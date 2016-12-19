
class WMFReferencePageBackgroundView: UIView {
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
        backgroundColor = UIColor.init(white: 0.0, alpha: 0.5)
        translatesAutoresizingMaskIntoConstraints = false
    }
}
