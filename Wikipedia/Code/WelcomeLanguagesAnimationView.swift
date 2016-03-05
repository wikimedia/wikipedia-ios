import Foundation

public class WelcomeLanguagesAnimationView : UIView {

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

        let horizontalOffset = CGFloat(0.35).wmf_denormalizeUsingReference(self.frame.width)
        let scaleZeroTransform = CATransform3DMakeScale(0, 0, 1)
        let leftTransform = CATransform3DMakeTranslation(-horizontalOffset, 0, 0)
        let lowerLeftTransform = CATransform3DMakeTranslation(-horizontalOffset, horizontalOffset, 0)
        let lowerRightTransform = CATransform3DMakeTranslation(horizontalOffset, horizontalOffset, 0)
        let linesTransform: CATransform3D  = CATransform3DConcat(scaleZeroTransform, leftTransform)
        
        bubbleLeftImgView.frame = self.bounds
        bubbleLeftImgView.image = UIImage(named: "ftux-left-bubble")
        bubbleLeftImgView.contentMode = UIViewContentMode.ScaleAspectFit;
        bubbleLeftImgView.layer.zPosition = 102
        bubbleLeftImgView.layer.opacity = 0
        bubbleLeftImgView.layer.transform = CATransform3DConcat(scaleZeroTransform, lowerLeftTransform);
        self.addSubview(bubbleLeftImgView)

        bubbleRightImgView.frame = self.bounds
        bubbleRightImgView.image = UIImage(named: "ftux-right-bubble")
        bubbleRightImgView.contentMode = UIViewContentMode.ScaleAspectFit;
        bubbleRightImgView.layer.zPosition = 101
        bubbleRightImgView.layer.opacity = 0
        bubbleRightImgView.layer.transform = CATransform3DConcat(scaleZeroTransform, lowerRightTransform);
        self.addSubview(bubbleRightImgView)

        self.solidCircle = WelcomeCircleShapeLayer(
            unitRadius: 0.31,
            unitOrigin: CGPointMake(0.39, 0.5),
            referenceSize: self.frame.size,
            isDashed: false,
            transform: scaleZeroTransform,
            opacity:0.0
        )
        self.layer.addSublayer(self.solidCircle!)
        
        self.dashedCircle = WelcomeCircleShapeLayer(
            unitRadius: 0.31,
            unitOrigin: CGPointMake(0.508, 0.518),
            referenceSize: self.frame.size,
            isDashed: true,
            transform: scaleZeroTransform,
            opacity:0.0
        )
        self.layer.addSublayer(self.dashedCircle!)
        
        self.plus1 = WelcomePlusShapeLayer(
            unitOrigin: CGPointMake(0.825, 0.225),
            unitWidth: 0.05,
            referenceSize: self.frame.size,
            transform: scaleZeroTransform,
            opacity: 0.0
        )
        self.layer.addSublayer(self.plus1!)

        self.plus2 = WelcomePlusShapeLayer(
            unitOrigin: CGPointMake(0.755, 0.17),
            unitWidth: 0.05,
            referenceSize: self.frame.size,
            transform: scaleZeroTransform,
            opacity: 0.0
        )
        self.layer.addSublayer(self.plus2!)

        self.plus3 = WelcomePlusShapeLayer(
            unitOrigin: CGPointMake(0.112, 0.353),
            unitWidth: 0.05,
            referenceSize: self.frame.size,
            transform: scaleZeroTransform,
            opacity: 0.0
        )
        self.layer.addSublayer(self.plus3!)
        
        self.line1 = WelcomeLineShapeLayer(
            unitOrigin: CGPointMake(0.845, 0.865),
            unitWidth: 0.135,
            referenceSize: self.frame.size,
            transform: linesTransform,
            opacity: 0.0
        )
        self.layer.addSublayer(self.line1!)

        self.line2 = WelcomeLineShapeLayer(
            unitOrigin: CGPointMake(0.255, 0.162),
            unitWidth: 0.135,
            referenceSize: self.frame.size,
            transform: linesTransform,
            opacity: 0.0
        )
        self.layer.addSublayer(self.line2!)

        self.line3 = WelcomeLineShapeLayer(
            unitOrigin: CGPointMake(0.205, 0.127),
            unitWidth: 0.135,
            referenceSize: self.frame.size,
            transform: linesTransform,
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
