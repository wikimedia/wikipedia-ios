import Foundation

public class WelcomeIntroAnimationView : WelcomeAnimationView {

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
        baseImgView.contentMode = UIViewContentMode.ScaleAspectFit
        baseImgView.layer.zPosition = 101
        baseImgView.layer.transform = CATransform3DIdentity
        self.addSubview(baseImgView)

        let tubeRotationPoint = CGPointMake(0.576, 0.38)

        let initialTubeRotationTransform = CATransform3D.wmf_rotationTransformWithDegrees(0.0)
        
        let rectCorrectingForRotation = CGRectMake(
            self.bounds.origin.x - (self.bounds.size.width * (0.5 - tubeRotationPoint.x)),
            self.bounds.origin.y - (self.bounds.size.height * (0.5 - tubeRotationPoint.y)),
            self.bounds.size.width,
            self.bounds.size.height
        )
        
        tubeImgView.frame = rectCorrectingForRotation
        tubeImgView.image = UIImage(named: "ftux-telescope-tube")
        tubeImgView.contentMode = UIViewContentMode.ScaleAspectFit
        tubeImgView.layer.zPosition = 101
        tubeImgView.layer.transform = initialTubeRotationTransform
        tubeImgView.layer.anchorPoint = tubeRotationPoint
        self.addSubview(tubeImgView)
        
        self.solidCircle = WelcomeCircleShapeLayer(
            unitRadius: 0.32,
            unitOrigin: CGPointMake(0.625, 0.55),
            referenceSize: self.frame.size,
            isDashed: false,
            transform: self.wmf_scaleZeroTransform,
            opacity:0.0
        )
        self.layer.addSublayer(self.solidCircle!)

        self.dashedCircle = WelcomeCircleShapeLayer(
            unitRadius: 0.304,
            unitOrigin: CGPointMake(0.521, 0.531),
            referenceSize: self.frame.size,
            isDashed: true,
            transform: self.wmf_scaleZeroTransform,
            opacity:0.0
        )
        self.layer.addSublayer(self.dashedCircle!)

        self.plus1 = WelcomePlusShapeLayer(
            unitOrigin: CGPointMake(0.033, 0.219),
            unitWidth: 0.05,
            referenceSize: self.frame.size,
            transform: self.wmf_scaleZeroTransform,
            opacity: 0.0
        )
        self.layer.addSublayer(self.plus1!)

        self.plus2 = WelcomePlusShapeLayer(
            unitOrigin: CGPointMake(0.11, 0.16),
            unitWidth: 0.05,
            referenceSize: self.frame.size,
            transform: self.wmf_scaleZeroTransform,
            opacity: 0.0
        )
        self.layer.addSublayer(self.plus2!)

        self.line1 = WelcomeLineShapeLayer(
            unitOrigin: CGPointMake(0.91, 0.778),
            unitWidth: 0.144,
            referenceSize: self.frame.size,
            transform: self.wmf_scaleZeroAndRightTransform,
            opacity: 0.0
        )
        self.layer.addSublayer(self.line1!)
        
        self.line2 = WelcomeLineShapeLayer(
            unitOrigin: CGPointMake(0.836, 0.81),
            unitWidth: 0.06,
            referenceSize: self.frame.size,
            transform: self.wmf_scaleZeroAndRightTransform,
            opacity: 0.0
        )
        self.layer.addSublayer(self.line2!)

        self.line3 = WelcomeLineShapeLayer(
            unitOrigin: CGPointMake(0.907, 0.81),
            unitWidth: 0.0125,
            referenceSize: self.frame.size,
            transform: self.wmf_scaleZeroAndRightTransform,
            opacity: 0.0
        )
        self.layer.addSublayer(self.line3!)
    }
    
    public func beginAnimations() {
        CATransaction.begin()
        
        let tubeOvershootRotationTransform = CATransform3D.wmf_rotationTransformWithDegrees(15.0)
        let tubeFinalRotationTransform = CATransform3D.wmf_rotationTransformWithDegrees(-2.0)

        tubeImgView.layer.wmf_animateToOpacity(1.0,
            transform:tubeOvershootRotationTransform,
            delay: 0.8,
            duration: 0.7
        )

        tubeImgView.layer.wmf_animateToOpacity(1.0,
            transform:tubeFinalRotationTransform,
            delay: 1.5,
            duration: 0.7
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
