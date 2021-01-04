import Foundation

open class WMFWelcomeAnalyticsAnimationView : WMFWelcomeAnimationView {

    lazy var phoneImgView: UIImageView = {
        let imgView = UIImageView(frame: bounds)
        imgView.image = UIImage(named: "ftux-analytics-phone")
        imgView.contentMode = UIView.ContentMode.scaleAspectFit
        imgView.layer.zPosition = 101
        imgView.layer.opacity = 0
        imgView.layer.transform = wmf_lowerTransform
        return imgView
    }()
    
    lazy var chartImgView: UIImageView = {
        let imgView = UIImageView(frame: bounds)
        imgView.image = UIImage(named: "ftux-analytics-chart")
        imgView.contentMode = UIView.ContentMode.scaleAspectFit
        imgView.layer.zPosition = 102
        imgView.layer.opacity = 0
        
        // Adjust chartImgView anchorPoint so zoom-in happens at that point (center of the chart circle)
        let anchorPoint = CGPoint(x: 0.71666, y: 0.41333)
        imgView.layer.anchorPoint = anchorPoint
        imgView.layer.position = anchorPoint.wmf_denormalizeUsingSize(imgView.frame.size)
        
        imgView.layer.transform = wmf_scaleZeroTransform
        return imgView
    }()
    
    override open func addAnimationElementsScaledToCurrentFrameSize(){
        super.addAnimationElementsScaledToCurrentFrameSize()
        removeExistingSubviewsAndSublayers()
        addSubview(phoneImgView)
        addSubview(chartImgView)
        /*
        isUserInteractionEnabled = true
        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleTapGestureRecognizer(_:))))
         */
    }
    /*
    @objc func handleTapGestureRecognizer(_ gestureRecognizer: UITapGestureRecognizer) {
        DDLogDebug("chartImgView anchorPoint \(gestureRecognizer.location(in: self).wmf_normalizeUsingSize(frame.size))")
    }
    */
    override open func beginAnimations() {
        super.beginAnimations()
        CATransaction.begin()
        
        phoneImgView.layer.wmf_animateToOpacity(
            1.0,
            transform: CATransform3DIdentity,
            delay: 0.1,
            duration: 0.9
        )
        
        chartImgView.layer.wmf_animateToOpacity(
            1.0,
            transform: CATransform3DIdentity,
            delay: 0.9,
            duration: 0.4
        )
                
        CATransaction.commit()
    }
}
