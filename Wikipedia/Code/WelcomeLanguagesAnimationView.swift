import Foundation

public class WelcomeLanguagesAnimationView : WelcomeAnimationView {

    var bubbleLeftImgView: UIImageView
    var bubbleRightImgView: UIImageView
    var dashedCircle: WelcomeCircleShapeLayer?
    var solidCircle: WelcomeCircleShapeLayer?
    var plus1: WelcomePlusShapeLayer?
    var plus2: WelcomePlusShapeLayer?
    var plus3: WelcomePlusShapeLayer?
    var line1: WelcomeLineShapeLayer?
    var line2: WelcomeLineShapeLayer?
    var line3: WelcomeLineShapeLayer?

    required public init?(coder aDecoder: NSCoder) {
        self.bubbleLeftImgView = UIImageView()
        self.bubbleRightImgView = UIImageView()
        super.init(coder: aDecoder)
    }
    
    override public func didMoveToSuperview() {
        super.didMoveToSuperview()
        
        bubbleLeftImgView.frame = self.bounds
        bubbleLeftImgView.image = UIImage(named: "ftux-left-bubble")
        bubbleLeftImgView.contentMode = UIViewContentMode.ScaleAspectFit
        bubbleLeftImgView.layer.zPosition = 102
        bubbleLeftImgView.layer.opacity = 0
        bubbleLeftImgView.layer.transform = self.wmf_scaleZeroAndLowerLeftTransform
        self.addSubview(bubbleLeftImgView)

        bubbleRightImgView.frame = self.bounds
        bubbleRightImgView.image = UIImage(named: "ftux-right-bubble")
        bubbleRightImgView.contentMode = UIViewContentMode.ScaleAspectFit
        bubbleRightImgView.layer.zPosition = 101
        bubbleRightImgView.layer.opacity = 0
        bubbleRightImgView.layer.transform = self.wmf_scaleZeroAndLowerRightTransform
        self.addSubview(bubbleRightImgView)

        self.solidCircle = WelcomeCircleShapeLayer(
            unitRadius: 0.31,
            unitOrigin: CGPointMake(0.39, 0.5),
            referenceSize: self.frame.size,
            isDashed: false,
            transform: self.wmf_scaleZeroTransform,
            opacity:0.0
        )
        self.layer.addSublayer(self.solidCircle!)
        
        self.dashedCircle = WelcomeCircleShapeLayer(
            unitRadius: 0.31,
            unitOrigin: CGPointMake(0.508, 0.518),
            referenceSize: self.frame.size,
            isDashed: true,
            transform: self.wmf_scaleZeroTransform,
            opacity:0.0
        )
        self.layer.addSublayer(self.dashedCircle!)
        
        self.plus1 = WelcomePlusShapeLayer(
            unitOrigin: CGPointMake(0.825, 0.225),
            unitWidth: 0.05,
            referenceSize: self.frame.size,
            transform: self.wmf_scaleZeroTransform,
            opacity: 0.0
        )
        self.layer.addSublayer(self.plus1!)

        self.plus2 = WelcomePlusShapeLayer(
            unitOrigin: CGPointMake(0.755, 0.17),
            unitWidth: 0.05,
            referenceSize: self.frame.size,
            transform: self.wmf_scaleZeroTransform,
            opacity: 0.0
        )
        self.layer.addSublayer(self.plus2!)

        self.plus3 = WelcomePlusShapeLayer(
            unitOrigin: CGPointMake(0.112, 0.353),
            unitWidth: 0.05,
            referenceSize: self.frame.size,
            transform: self.wmf_scaleZeroTransform,
            opacity: 0.0
        )
        self.layer.addSublayer(self.plus3!)
        
        self.line1 = WelcomeLineShapeLayer(
            unitOrigin: CGPointMake(0.845, 0.865),
            unitWidth: 0.135,
            referenceSize: self.frame.size,
            transform: self.wmf_scaleZeroAndLeftTransform,
            opacity: 0.0
        )
        self.layer.addSublayer(self.line1!)

        self.line2 = WelcomeLineShapeLayer(
            unitOrigin: CGPointMake(0.255, 0.162),
            unitWidth: 0.135,
            referenceSize: self.frame.size,
            transform: self.wmf_scaleZeroAndLeftTransform,
            opacity: 0.0
        )
        self.layer.addSublayer(self.line2!)

        self.line3 = WelcomeLineShapeLayer(
            unitOrigin: CGPointMake(0.205, 0.127),
            unitWidth: 0.135,
            referenceSize: self.frame.size,
            transform: self.wmf_scaleZeroAndLeftTransform,
            opacity: 0.0
        )
        self.layer.addSublayer(self.line3!)
    }

    public func beginAnimations() {
        CATransaction.begin()
        
        bubbleLeftImgView.layer.wmf_animateToOpacity(1.0,
            transform: CATransform3DIdentity,
            delay: 0.1,
            duration: 1.0
        )
        
        bubbleRightImgView.layer.wmf_animateToOpacity(1.0,
            transform: CATransform3DIdentity,
            delay: 0.3,
            duration: 1.0
        )
        
        self.solidCircle?.wmf_animateToOpacity(0.04,
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
            self.plus3!,
            self.line1!,
            self.line2!,
            self.line3!
            ].map(animate)
        
        CATransaction.commit()
    }
}
