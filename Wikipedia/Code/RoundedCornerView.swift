import UIKit

class RoundedCornerView: UIView {
    
    var corners: UIRectCorner = [] {
        didSet {
            update()
        }
    }
    var radius: CGFloat = 0 {
        didSet {
            update()
        }
    }
    
    private var currentSize = CGSize.zero
    
    func update() {
        currentSize = bounds.size
        let radii = CGSize(width: radius, height: radius)
        let bezierPath = UIBezierPath(roundedRect: bounds, byRoundingCorners: corners, cornerRadii: radii)
        let shapeLayer = CAShapeLayer()
        shapeLayer.frame = bounds
        shapeLayer.path = bezierPath.cgPath
        layer.mask = shapeLayer
    }
    
    private func updateIfSizeChanged() {
        if currentSize != bounds.size {
            update()
        }
    }
    
    override var bounds: CGRect {
        didSet {
            updateIfSizeChanged()
        }
    }
    
    override var frame: CGRect {
        didSet {
            updateIfSizeChanged()
        }
    }
}
