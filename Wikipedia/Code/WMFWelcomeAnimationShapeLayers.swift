import Foundation
import CoreGraphics

open class WelcomeShapeLayer : CAShapeLayer {
    public init(referenceSize: CGSize, transform: CATransform3D, opacity: CGFloat) {
        super.init()

        self.lineCap = "round"
        self.strokeEnd = 1.0
        self.zPosition = 100
        self.lineWidth = CGFloat(0.014).wmf_denormalizeUsingReference(referenceSize.width)
        self.transform = transform
        self.opacity = Float(opacity)
        self.strokeColor = UIColor.black.cgColor
        self.fillColor = UIColor.black.cgColor
        
    }
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    public required override init() {
        super.init()
    }
}

open class WelcomeBarShapeLayer : WelcomeShapeLayer {
    public required init(unitRect: CGRect, referenceSize: CGSize, transform: CATransform3D) {
        super.init(referenceSize: referenceSize, transform: transform, opacity:1.0)

        var rect = unitRect.wmf_denormalizeUsingSize(referenceSize)
        self.position = rect.origin
        rect.origin = CGPoint.zero // zero so position is via the position property, not the path
        self.path = UIBezierPath(roundedRect: rect, cornerRadius: 0.0).cgPath
        self.strokeColor = UIColor.clear.cgColor
        
    }
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    public required init() {
        super.init()
    }
}

open class WelcomeCircleShapeLayer : WelcomeShapeLayer {
    public required init(unitRadius: CGFloat, unitOrigin:CGPoint, referenceSize: CGSize, isDashed: Bool, transform: CATransform3D, opacity: CGFloat) {
        super.init(referenceSize: referenceSize, transform: transform, opacity: opacity)

        self.position = unitOrigin.wmf_denormalizeUsingSize(referenceSize)
        self.path = UIBezierPath(
            arcCenter: CGPoint.zero,
            radius: unitRadius.wmf_denormalizeUsingReference(referenceSize.width),
            startAngle: 0.0,
            endAngle: CGFloat(Double.pi * 2.0),
            clockwise: true
            ).cgPath
        if (isDashed){
            self.lineDashPattern = [
                NSNumber(value: CGFloat(0.029).wmf_denormalizeUsingReference(referenceSize.width).native),
                NSNumber(value: CGFloat(0.047).wmf_denormalizeUsingReference(referenceSize.width).native)
            ]
            self.fillColor = UIColor.clear.cgColor
        }else{
            self.strokeColor = UIColor.clear.cgColor
        }
        
    }
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    public required init() {
        super.init()
    }
}

open class WelcomePlusShapeLayer : WelcomeShapeLayer {
    public required init(unitOrigin: CGPoint, unitWidth: CGFloat, referenceSize: CGSize, transform: CATransform3D, opacity: CGFloat) {
        super.init(referenceSize: referenceSize, transform: transform, opacity: opacity)

        self.position = unitOrigin.wmf_denormalizeUsingSize(referenceSize)
        let width = unitWidth.wmf_denormalizeUsingReference(referenceSize.width)
        let path = UIBezierPath()
        path.move(to: CGPoint(x: width * -0.5, y: 0.0))
        path.addLine(to: CGPoint(x: width * 0.5, y: 0.0))
        path.move(to: CGPoint(x: 0.0, y: width * -0.5))
        path.addLine(to: CGPoint(x: 0.0, y: width * 0.5))
        self.path = path.cgPath

    }
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    public required init() {
        super.init()
    }
}

open class WelcomeLineShapeLayer : WelcomeShapeLayer {
    public required init(unitOrigin: CGPoint, unitWidth: CGFloat, referenceSize: CGSize, transform: CATransform3D, opacity: CGFloat) {
        super.init(referenceSize: referenceSize, transform: transform, opacity: opacity)

        self.position = unitOrigin.wmf_denormalizeUsingSize(referenceSize)
        let width = unitWidth.wmf_denormalizeUsingReference(referenceSize.width)
        let path = UIBezierPath()
        path.move(to: CGPoint(x: width * -0.5, y: 0.0))
        path.addLine(to: CGPoint(x: width * 0.5, y: 0.0))
        self.path = path.cgPath
        
    }
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    public required init() {
        super.init()
    }
}
