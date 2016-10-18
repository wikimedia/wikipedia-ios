import Foundation

public class WelcomeIntroAnimationView : WelcomeAnimationView {

    lazy var tubeImgView: UIImageView = {
        let tubeRotationPoint = CGPointMake(0.576, 0.38)
        let initialTubeRotationTransform = CATransform3D.wmf_rotationTransformWithDegrees(0.0)
        let rectCorrectingForRotation = CGRectMake(
            self.bounds.origin.x - (self.bounds.size.width * (0.5 - tubeRotationPoint.x)),
            self.bounds.origin.y - (self.bounds.size.height * (0.5 - tubeRotationPoint.y)),
            self.bounds.size.width,
            self.bounds.size.height
        )
        let imgView = UIImageView(frame: rectCorrectingForRotation)
        imgView.image = UIImage(named: "ftux-telescope-tube")
        imgView.contentMode = UIViewContentMode.ScaleAspectFit
        imgView.layer.zPosition = 101
        imgView.layer.transform = initialTubeRotationTransform
        imgView.layer.anchorPoint = tubeRotationPoint
        return imgView
    }()

    lazy var baseImgView: UIImageView = {
        let imgView = UIImageView(frame: self.bounds)
        imgView.image = UIImage(named: "ftux-telescope-base")
        imgView.contentMode = UIViewContentMode.ScaleAspectFit
        imgView.layer.zPosition = 101
        imgView.layer.transform = CATransform3DIdentity
        return imgView
    }()

    lazy var dashedCircle: WelcomeCircleShapeLayer = {
        return WelcomeCircleShapeLayer(
            unitRadius: 0.304,
            unitOrigin: CGPointMake(0.521, 0.531),
            referenceSize: self.frame.size,
            isDashed: true,
            transform: self.wmf_scaleZeroTransform,
            opacity:0.0
        )
    }()
    
    lazy var solidCircle: WelcomeCircleShapeLayer = {
        return WelcomeCircleShapeLayer(
            unitRadius: 0.32,
            unitOrigin: CGPointMake(0.625, 0.55),
            referenceSize: self.frame.size,
            isDashed: false,
            transform: self.wmf_scaleZeroTransform,
            opacity:0.0
        )
    }()
    
    lazy var plus1: WelcomePlusShapeLayer = {
        return WelcomePlusShapeLayer(
            unitOrigin: CGPointMake(0.033, 0.219),
            unitWidth: 0.05,
            referenceSize: self.frame.size,
            transform: self.wmf_scaleZeroTransform,
            opacity: 0.0
        )
    }()
    
    lazy var plus2: WelcomePlusShapeLayer = {
        return WelcomePlusShapeLayer(
            unitOrigin: CGPointMake(0.11, 0.16),
            unitWidth: 0.05,
            referenceSize: self.frame.size,
            transform: self.wmf_scaleZeroTransform,
            opacity: 0.0
        )
    }()
    
    lazy var line1: WelcomeLineShapeLayer = {
        return WelcomeLineShapeLayer(
            unitOrigin: CGPointMake(0.91, 0.778),
            unitWidth: 0.144,
            referenceSize: self.frame.size,
            transform: self.wmf_scaleZeroAndRightTransform,
            opacity: 0.0
        )
    }()
    
    lazy var line2: WelcomeLineShapeLayer = {
        return WelcomeLineShapeLayer(
            unitOrigin: CGPointMake(0.836, 0.81),
            unitWidth: 0.06,
            referenceSize: self.frame.size,
            transform: self.wmf_scaleZeroAndRightTransform,
            opacity: 0.0
        )
    }()
    
    lazy var line3: WelcomeLineShapeLayer = {
        return WelcomeLineShapeLayer(
            unitOrigin: CGPointMake(0.907, 0.81),
            unitWidth: 0.0125,
            referenceSize: self.frame.size,
            transform: self.wmf_scaleZeroAndRightTransform,
            opacity: 0.0
        )
    }()
    
    override public func addAnimationElementsScaledToCurrentFrameSize(){
        removeExistingSubviewsAndSublayers()

        self.addSubview(self.baseImgView)
        self.addSubview(self.tubeImgView)
        
        _ = [
            self.solidCircle,
            self.dashedCircle,
            self.plus1,
            self.plus2,
            self.line1,
            self.line2,
            self.line3
            ].map({ (layer: CALayer) -> () in
                self.layer.addSublayer(layer)
            })
    }
    
    override public func beginAnimations() {
        CATransaction.begin()
        
        let tubeOvershootRotationTransform = CATransform3D.wmf_rotationTransformWithDegrees(15.0)
        let tubeFinalRotationTransform = CATransform3D.wmf_rotationTransformWithDegrees(-2.0)

        tubeImgView.layer.wmf_animateToOpacity(1.0,
            transform:tubeOvershootRotationTransform,
            delay: 0.8,
            duration: 0.9
        )

        tubeImgView.layer.wmf_animateToOpacity(1.0,
            transform:tubeFinalRotationTransform,
            delay: 1.8,
            duration: 0.9
        )

        self.solidCircle.wmf_animateToOpacity(0.09,
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
            self.dashedCircle,
            self.plus1,
            self.plus2,
            self.line1,
            self.line2,
            self.line3
            ].map(animate)
        
        CATransaction.commit()
    }
}
