import Foundation

public class WelcomeIntroAnimationView : UIView {

    var tubeImgView: UIImageView
    var dashedCircle: WelcomeCircleShapeLayer?
    var solidCircle: WelcomeCircleShapeLayer?
    var plus1: WelcomePlusShapeLayer?
    var plus2: WelcomePlusShapeLayer?
    var line1: WelcomeLineShapeLayer?
    var line2: WelcomeLineShapeLayer?
    var line3: WelcomeLineShapeLayer?
    
    required public init?(coder aDecoder: NSCoder) {
        self.tubeImgView = UIImageView()
        super.init(coder: aDecoder)
    }
    
    override public func didMoveToSuperview() {
        super.didMoveToSuperview()

        let baseImgView = UIImageView(frame: self.bounds)
        baseImgView.image = UIImage(named: "ftux-telescope-base")
        baseImgView.contentMode = UIViewContentMode.ScaleAspectFit;
        baseImgView.layer.zPosition = 101
        baseImgView.layer.transform = CATransform3DIdentity;
        self.addSubview(baseImgView)

        let tubeRotationPoint = CGPointMake(0.576, 0.38)

        let initialTubeRotationTransform = CATransform3D.wmf_rotationTransformWithDegrees(-25.0)
        
        let rectCorrectingForRotation = CGRectMake(
            self.bounds.origin.x - (self.bounds.size.width * (0.5 - tubeRotationPoint.x)),
            self.bounds.origin.y - (self.bounds.size.height * (0.5 - tubeRotationPoint.y)),
            self.bounds.size.width,
            self.bounds.size.height
        )
        
        tubeImgView.frame = rectCorrectingForRotation
        tubeImgView.image = UIImage(named: "ftux-telescope-tube")
        tubeImgView.contentMode = UIViewContentMode.ScaleAspectFit;
        tubeImgView.layer.zPosition = 101
        tubeImgView.layer.transform = initialTubeRotationTransform;
        tubeImgView.layer.anchorPoint = tubeRotationPoint
        self.addSubview(tubeImgView)

        let horizontalOffset = CGFloat(0.35).wmf_denormalizeUsingReference(self.frame.width)
        let scaleZeroTransform = CATransform3DMakeScale(0, 0, 1)
        let rightTransform = CATransform3DMakeTranslation(horizontalOffset, 0, 0)
        let linesTransform: CATransform3D  = CATransform3DConcat(scaleZeroTransform, rightTransform)
        
        self.solidCircle = WelcomeCircleShapeLayer(
            unitRadius: 0.32,
            unitOrigin: CGPointMake(0.625, 0.55),
            referenceSize: self.frame.size,
            isDashed: false,
            transform: scaleZeroTransform,
            opacity:0.0
        )
        self.layer.addSublayer(self.solidCircle!)

        self.dashedCircle = WelcomeCircleShapeLayer(
            unitRadius: 0.304,
            unitOrigin: CGPointMake(0.521, 0.531),
            referenceSize: self.frame.size,
            isDashed: true,
            transform: scaleZeroTransform,
            opacity:0.0
        )
        self.layer.addSublayer(self.dashedCircle!)

        self.plus1 = WelcomePlusShapeLayer(
            unitOrigin: CGPointMake(0.033, 0.219),
            unitWidth: 0.05,
            referenceSize: self.frame.size,
            transform: scaleZeroTransform,
            opacity: 0.0
        )
        self.layer.addSublayer(self.plus1!)

        self.plus2 = WelcomePlusShapeLayer(
            unitOrigin: CGPointMake(0.11, 0.16),
            unitWidth: 0.05,
            referenceSize: self.frame.size,
            transform: scaleZeroTransform,
            opacity: 0.0
        )
        self.layer.addSublayer(self.plus2!)

        self.line1 = WelcomeLineShapeLayer(
            unitOrigin: CGPointMake(0.91, 0.778),
            unitWidth: 0.144,
            referenceSize: self.frame.size,
            transform: linesTransform,
            opacity: 0.0
        )
        self.layer.addSublayer(self.line1!)
        
        self.line2 = WelcomeLineShapeLayer(
            unitOrigin: CGPointMake(0.836, 0.81),
            unitWidth: 0.06,
            referenceSize: self.frame.size,
            transform: linesTransform,
            opacity: 0.0
        )
        self.layer.addSublayer(self.line2!)

        self.line3 = WelcomeLineShapeLayer(
            unitOrigin: CGPointMake(0.907, 0.81),
            unitWidth: 0.0125,
            referenceSize: self.frame.size,
            transform: linesTransform,
            opacity: 0.0
        )
        self.layer.addSublayer(self.line3!)
    }
    
    public func beginAnimations() {
        CATransaction.begin()
        
        let tubeOvershootRotationTransform = CATransform3D.wmf_rotationTransformWithDegrees(10.0)
        let tubeFinalRotationTransform = CATransform3D.wmf_rotationTransformWithDegrees(5.0)

        tubeImgView.layer.wmf_animateToOpacity(1.0,
            transform:tubeOvershootRotationTransform,
            delay: 0.4,
            duration: 1.3
        )

        tubeImgView.layer.wmf_animateToOpacity(1.0,
            transform:tubeFinalRotationTransform,
            delay: 1.75,
            duration: 1.3
        )

        self.solidCircle?.wmf_animateToOpacity(0.09,
            transform: CATransform3DIdentity,
            delay: 0.3,
            duration: 1.0
        )

        let animate = { (layer: CALayer) -> () in
            layer.wmf_animateToOpacity(0.15,
                transform: CATransform3DIdentity,
                delay: 0.3,
                duration: 1.0
            )
        }
        
        _ = [
            self.dashedCircle!,
            self.plus1!,
            self.plus2!,
            self.line1!,
            self.line2!,
            self.line3!
            ].map(animate)
        
        CATransaction.commit()
    }
}
