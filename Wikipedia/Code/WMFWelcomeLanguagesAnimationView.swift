import Foundation

open class WMFWelcomeLanguagesAnimationView : WMFWelcomeAnimationView {

    lazy var bubbleLeftImgView: UIImageView = {
        let imgView = UIImageView(frame: bounds)
        imgView.image = UIImage(named: "ftux-left-bubble")
        imgView.contentMode = UIViewContentMode.scaleAspectFit
        imgView.layer.zPosition = 102
        imgView.layer.opacity = 0
        imgView.layer.transform = wmf_scaleZeroAndLowerLeftTransform
        return imgView
    }()
    
    lazy var bubbleRightImgView: UIImageView = {
        let imgView = UIImageView(frame: bounds)
        imgView.image = UIImage(named: "ftux-right-bubble")
        imgView.contentMode = UIViewContentMode.scaleAspectFit
        imgView.layer.zPosition = 101
        imgView.layer.opacity = 0
        imgView.layer.transform = wmf_scaleZeroAndLowerRightTransform
        return imgView
    }()
    
    lazy var dashedCircle: WelcomeCircleShapeLayer = {
        return WelcomeCircleShapeLayer(
            unitRadius: 0.31,
            unitOrigin: CGPoint(x: 0.508, y: 0.518),
            referenceSize: frame.size,
            isDashed: true,
            transform: wmf_scaleZeroTransform,
            opacity:0.0
        )
    }()
    
    lazy var solidCircle: WelcomeCircleShapeLayer = {
        return WelcomeCircleShapeLayer(
            unitRadius: 0.31,
            unitOrigin: CGPoint(x: 0.39, y: 0.5),
            referenceSize: frame.size,
            isDashed: false,
            transform: wmf_scaleZeroTransform,
            opacity:0.0
        )
    }()
    
    lazy var plus1: WelcomePlusShapeLayer = {
        return WelcomePlusShapeLayer(
            unitOrigin: CGPoint(x: 0.825, y: 0.225),
            unitWidth: 0.05,
            referenceSize: frame.size,
            transform: wmf_scaleZeroTransform,
            opacity: 0.0
        )
    }()
    
    lazy var plus2: WelcomePlusShapeLayer = {
        return WelcomePlusShapeLayer(
            unitOrigin: CGPoint(x: 0.755, y: 0.17),
            unitWidth: 0.05,
            referenceSize: frame.size,
            transform: wmf_scaleZeroTransform,
            opacity: 0.0
        )
    }()
    
    lazy var plus3: WelcomePlusShapeLayer = {
        return WelcomePlusShapeLayer(
            unitOrigin: CGPoint(x: 0.112, y: 0.353),
            unitWidth: 0.05,
            referenceSize: frame.size,
            transform: wmf_scaleZeroTransform,
            opacity: 0.0
        )
    }()
    
    lazy var line1: WelcomeLineShapeLayer = {
        return WelcomeLineShapeLayer(
            unitOrigin: CGPoint(x: 0.845, y: 0.865),
            unitWidth: 0.135,
            referenceSize: frame.size,
            transform: wmf_scaleZeroAndLeftTransform,
            opacity: 0.0
        )
    }()
    
    lazy var line2: WelcomeLineShapeLayer = {
        return WelcomeLineShapeLayer(
            unitOrigin: CGPoint(x: 0.255, y: 0.162),
            unitWidth: 0.135,
            referenceSize: frame.size,
            transform: wmf_scaleZeroAndLeftTransform,
            opacity: 0.0
        )
    }()
    
    lazy var line3: WelcomeLineShapeLayer = {
        return WelcomeLineShapeLayer(
            unitOrigin: CGPoint(x: 0.205, y: 0.127),
            unitWidth: 0.135,
            referenceSize: frame.size,
            transform: wmf_scaleZeroAndLeftTransform,
            opacity: 0.0
        )
    }()
    
    override open func addAnimationElementsScaledToCurrentFrameSize(){
        removeExistingSubviewsAndSublayers()
        
        addSubview(bubbleLeftImgView)
        addSubview(bubbleRightImgView)

        [
            solidCircle,
            dashedCircle,
            plus1,
            plus2,
            plus3,
            line1,
            line2,
            line3
            ].forEach(layer.addSublayer)
    }

    override open func beginAnimations() {
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
        
        solidCircle.wmf_animateToOpacity(0.04,
            transform: CATransform3DIdentity,
            delay: 0.3,
            duration: 1.0
        )
        
        let animate = { (layer: CALayer) in
            layer.wmf_animateToOpacity(0.15,
                transform: CATransform3DIdentity,
                delay: 0.3,
                duration: 1.0
            )
        }
        
        [
            dashedCircle,
            plus1,
            plus2,
            plus3,
            line1,
            line2,
            line3
            ].forEach(animate)
        
        CATransaction.commit()
    }
}
