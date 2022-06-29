import Foundation

open class WMFWelcomeLanguagesAnimationView : WMFWelcomeAnimationView {

    lazy var bubbleLeftImgView: UIImageView = {
        let imgView = UIImageView(frame: bounds)
        imgView.image = UIImage(named: "ftux-langs-left")
        imgView.contentMode = UIView.ContentMode.scaleAspectFit
        imgView.layer.zPosition = 101
        imgView.layer.opacity = 0
        imgView.layer.transform = wmf_scaleZeroAndLowerLeftTransform
        return imgView
    }()
    
    lazy var bubbleRightImgView: UIImageView = {
        let imgView = UIImageView(frame: bounds)
        imgView.image = UIImage(named: "ftux-langs-right")
        imgView.contentMode = UIView.ContentMode.scaleAspectFit
        imgView.layer.zPosition = 102
        imgView.layer.opacity = 0
        imgView.layer.transform = wmf_scaleZeroAndLowerRightTransform
        return imgView
    }()
    
    override open func addAnimationElementsScaledToCurrentFrameSize() {
        super.addAnimationElementsScaledToCurrentFrameSize()
        removeExistingSubviewsAndSublayers()
        addSubview(bubbleLeftImgView)
        addSubview(bubbleRightImgView)
    }

    override open func beginAnimations() {
        super.beginAnimations()
        CATransaction.begin()
        
        bubbleLeftImgView.layer.wmf_animateToOpacity(
            1.0,
            transform: CATransform3DIdentity,
            delay: 0.1,
            duration: 1.0
        )
        
        bubbleRightImgView.layer.wmf_animateToOpacity(
            1.0,
            transform: CATransform3DIdentity,
            delay: 0.3,
            duration: 1.0
        )
                
        CATransaction.commit()
    }
}
