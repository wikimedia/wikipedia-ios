import Foundation

open class WMFWelcomeExplorationAnimationView : WMFWelcomeAnimationView {

    lazy var tubeImgView: UIImageView = {
        let imgView = UIImageView(frame: bounds)
        imgView.image = UIImage(named: "ftux-telescope-tube")
        imgView.contentMode = UIView.ContentMode.scaleAspectFit
        imgView.layer.zPosition = 102

        // Adjust tubeImgView anchorPoint so rotation happens at that point (at hinge)
        let anchorPoint = CGPoint(x: 0.50333, y: 0.64)
        imgView.layer.anchorPoint = anchorPoint
        imgView.layer.position = anchorPoint.wmf_denormalizeUsingSize(imgView.frame.size)
        
        imgView.layer.transform = wmf_lowerTransform
        imgView.layer.opacity = 0
        return imgView
    }()

    lazy var baseImgView: UIImageView = {
        let imgView = UIImageView(frame: bounds)
        imgView.image = UIImage(named: "ftux-telescope-base")
        imgView.contentMode = UIView.ContentMode.scaleAspectFit
        imgView.layer.zPosition = 101
        imgView.layer.transform = wmf_lowerTransform
        imgView.layer.opacity = 0
        return imgView
    }()
    
    override open func addAnimationElementsScaledToCurrentFrameSize() {
        super.addAnimationElementsScaledToCurrentFrameSize()
        removeExistingSubviewsAndSublayers()
        addSubview(baseImgView)
        addSubview(tubeImgView)
    }
    
    override open func beginAnimations() {
        super.beginAnimations()
        CATransaction.begin()
        
        let tubeOvershootRotationTransform = CATransform3D.wmf_rotationTransformWithDegrees(15.0)
        let tubeFinalRotationTransform = CATransform3D.wmf_rotationTransformWithDegrees(-2.0)

        baseImgView.layer.wmf_animateToOpacity(
            1.0,
            transform: CATransform3DIdentity,
            delay: 0.1,
            duration: 0.9
        )
        
        tubeImgView.layer.wmf_animateToOpacity(
            1.0,
            transform: CATransform3DIdentity,
            delay: 0.1,
            duration: 0.9
        )
        
        baseImgView.layer.wmf_animateToOpacity(
            1.0,
            transform: CATransform3DIdentity,
            delay: 1.1,
            duration: 0.9
        )
        
        tubeImgView.layer.wmf_animateToOpacity(
            1.0,
            transform: tubeOvershootRotationTransform,
            delay: 1.1,
            duration: 0.9
        )
        
        tubeImgView.layer.wmf_animateToOpacity(
            1.0,
            transform: tubeFinalRotationTransform,
            delay: 2.1,
            duration: 0.9
        )
        
        CATransaction.commit()
    }
}
