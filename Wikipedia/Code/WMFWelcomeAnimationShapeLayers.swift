import Foundation

public class WelcomeShapeLayer : CAShapeLayer {
    public init(referenceSize: CGSize, transform: CATransform3D, opacity: CGFloat) {
        super.init()

        self.lineCap = "round"
        self.strokeEnd = 1.0
        self.zPosition = 100
        self.lineWidth = CGFloat(0.014).wmf_denormalizeUsingReference(referenceSize.width)
        self.transform = transform
        self.opacity = Float(opacity)
        self.strokeColor = UIColor.blackColor().CGColor
        self.fillColor = UIColor.blackColor().CGColor
        
    }
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    public required override init() {
        super.init()
    }
}

public class WelcomeBarShapeLayer : WelcomeShapeLayer {
    public required init(unitRect: CGRect, referenceSize: CGSize, transform: CATransform3D) {
        super.init(referenceSize: referenceSize, transform: transform, opacity:1.0)

        var rect = unitRect.wmf_denormalizeUsingSize(referenceSize)
        self.position = rect.origin
        rect.origin = CGPointZero // zero so position is via the position property, not the path
        self.path = UIBezierPath(roundedRect: rect, cornerRadius: 0.0).CGPath
        self.strokeColor = UIColor.clearColor().CGColor
        
    }
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    public required init() {
        super.init()
    }
}

public class WelcomeCircleShapeLayer : WelcomeShapeLayer {
    public required init(unitRadius: CGFloat, unitOrigin:CGPoint, referenceSize: CGSize, isDashed: Bool, transform: CATransform3D, opacity: CGFloat) {
        super.init(referenceSize: referenceSize, transform: transform, opacity: opacity)

        self.position = unitOrigin.wmf_denormalizeUsingSize(referenceSize)
        self.path = UIBezierPath(
            arcCenter: CGPointZero,
            radius: unitRadius.wmf_denormalizeUsingReference(referenceSize.width),
            startAngle: 0.0,
            endAngle: CGFloat(M_PI * 2.0),
            clockwise: true
            ).CGPath
        if (isDashed){
            self.lineDashPattern = [
                CGFloat(0.029).wmf_denormalizeUsingReference(referenceSize.width),
                CGFloat(0.047).wmf_denormalizeUsingReference(referenceSize.width)
            ]
            self.fillColor = UIColor.clearColor().CGColor
        }else{
            self.strokeColor = UIColor.clearColor().CGColor
        }
        
    }
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    public required init() {
        super.init()
    }
}

public class WelcomePlusShapeLayer : WelcomeShapeLayer {
    public required init(unitOrigin: CGPoint, unitWidth: CGFloat, referenceSize: CGSize, transform: CATransform3D, opacity: CGFloat) {
        super.init(referenceSize: referenceSize, transform: transform, opacity: opacity)

        self.position = unitOrigin.wmf_denormalizeUsingSize(referenceSize)
        let width = unitWidth.wmf_denormalizeUsingReference(referenceSize.width)
        let path = UIBezierPath()
        path.moveToPoint(CGPointMake(width * -0.5, 0.0))
        path.addLineToPoint(CGPointMake(width * 0.5, 0.0))
        path.moveToPoint(CGPointMake(0.0, width * -0.5))
        path.addLineToPoint(CGPointMake(0.0, width * 0.5))
        self.path = path.CGPath

    }
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    public required init() {
        super.init()
    }
}

public class WelcomeLineShapeLayer : WelcomeShapeLayer {
    public required init(unitOrigin: CGPoint, unitWidth: CGFloat, referenceSize: CGSize, transform: CATransform3D, opacity: CGFloat) {
        super.init(referenceSize: referenceSize, transform: transform, opacity: opacity)

        self.position = unitOrigin.wmf_denormalizeUsingSize(referenceSize)
        let width = unitWidth.wmf_denormalizeUsingReference(referenceSize.width)
        let path = UIBezierPath()
        path.moveToPoint(CGPointMake(width * -0.5, 0.0))
        path.addLineToPoint(CGPointMake(width * 0.5, 0.0))
        self.path = path.CGPath
        
    }
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    public required init() {
        super.init()
    }
}
