import Foundation

open class WMFWelcomeExplorationAnimationView : WMFWelcomeAnimationView {

    lazy var tubeImgView: UIImageView = {
        let tubeRotationPoint = CGPoint(x: 0.576, y: 0.38)
        let initialTubeRotationTransform = CATransform3D.wmf_rotationTransformWithDegrees(0.0)
        let rectCorrectingForRotation = CGRect(
            x: bounds.origin.x - (bounds.size.width * (0.5 - tubeRotationPoint.x)),
            y: bounds.origin.y - (bounds.size.height * (0.5 - tubeRotationPoint.y)),
            width: bounds.size.width,
            height: bounds.size.height
        )
        let imgView = UIImageView(frame: rectCorrectingForRotation)
        imgView.image = UIImage(named: "ftux-telescope-tube")
        imgView.contentMode = UIViewContentMode.scaleAspectFit
        imgView.layer.zPosition = 101
        imgView.layer.transform = initialTubeRotationTransform
        imgView.layer.anchorPoint = tubeRotationPoint
        return imgView
    }()

    lazy var baseImgView: UIImageView = {
        let imgView = UIImageView(frame: bounds)
        imgView.image = UIImage(named: "ftux-telescope-base")
        imgView.contentMode = UIViewContentMode.scaleAspectFit
        imgView.layer.zPosition = 101
        imgView.layer.transform = CATransform3DIdentity
        return imgView
    }()
    
    override open func addAnimationElementsScaledToCurrentFrameSize(){
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
        
        CATransaction.commit()
    }
}
