import Foundation

public class WMFWelcomeAnimationView : UIView {
    
    // Reminder - these transforms are on WMFWelcomeAnimationView 
    // so they can scale proportionally to the view size.
    
    private var wmf_proportionalHorizontalOffset: CGFloat{
        return CGFloat(0.35).wmf_denormalizeUsingReference(self.frame.width)
    }
    private var wmf_proportionalVerticalOffset: CGFloat{
        return CGFloat(0.35).wmf_denormalizeUsingReference(self.frame.height)
    }
    
    
    var wmf_rightTransform: CATransform3D{
        return CATransform3DMakeTranslation(wmf_proportionalHorizontalOffset, 0, 0)
    }
    var wmf_leftTransform: CATransform3D{
        return CATransform3DMakeTranslation(-wmf_proportionalHorizontalOffset, 0, 0)
    }
    var wmf_lowerTransform: CATransform3D{
        return CATransform3DMakeTranslation(0.0, wmf_proportionalVerticalOffset, 0)
    }
    
    
    let wmf_scaleZeroTransform = CATransform3DMakeScale(0, 0, 1)

    var wmf_scaleZeroAndLeftTransform: CATransform3D{
        return CATransform3DConcat(self.wmf_scaleZeroTransform, wmf_leftTransform)
    }
    var wmf_scaleZeroAndRightTransform: CATransform3D{
        return CATransform3DConcat(self.wmf_scaleZeroTransform, wmf_rightTransform)
    }
    var wmf_scaleZeroAndLowerLeftTransform: CATransform3D{
        return CATransform3DConcat(wmf_scaleZeroAndLeftTransform, wmf_lowerTransform)
    }
    var wmf_scaleZeroAndLowerRightTransform: CATransform3D {
          return CATransform3DConcat(wmf_scaleZeroAndRightTransform, wmf_lowerTransform)
    }
    
    override public func didMoveToSuperview() {
        super.didMoveToSuperview()
        // Fix for: http://stackoverflow.com/a/39614714
        self.layoutIfNeeded()
    }
    
    public func wmf_beginAnimations() {
        
    }
    
    public func wmf_addAnimationElementsScaledToCurrentFrameSize(){
    
    }
    
    public func wmf_removeExistingSubviewsAndSublayers() {
        for subview in self.subviews {
            subview.removeFromSuperview()
        }
        if let sublayers = self.layer.sublayers {
            for sublayer in sublayers {
                sublayer.removeFromSuperlayer()
            }
        }
    }
}
