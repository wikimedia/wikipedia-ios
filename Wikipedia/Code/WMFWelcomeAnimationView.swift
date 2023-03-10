import Foundation

open class WMFWelcomeAnimationView : UIView, Themeable {
    var theme: Theme = Theme.standard
    
    public func apply(theme: Theme) {
        self.theme = theme
        backgroundColor = hasCircleBackground ? theme.colors.midBackground : .clear
    }
    // Reminder - these transforms are on WMFWelcomeAnimationView 
    // so they can scale proportionally to the view size.
    
    private var wmf_proportionalHorizontalOffset: CGFloat {
        return CGFloat(0.35).wmf_denormalizeUsingReference(frame.width)
    }
    private var wmf_proportionalVerticalOffset: CGFloat {
        return CGFloat(0.35).wmf_denormalizeUsingReference(frame.height)
    }
    
    
    var wmf_rightTransform: CATransform3D {
        return CATransform3DMakeTranslation(wmf_proportionalHorizontalOffset, 0, 0)
    }
    var wmf_leftTransform: CATransform3D {
        return CATransform3DMakeTranslation(-wmf_proportionalHorizontalOffset, 0, 0)
    }
    var wmf_lowerTransform: CATransform3D {
        return CATransform3DMakeTranslation(0.0, wmf_proportionalVerticalOffset, 0)
    }
    
    let wmf_scaleZeroTransform = CATransform3DMakeScale(0, 0, 1)

    var wmf_scaleZeroAndLeftTransform: CATransform3D {
        return CATransform3DConcat(wmf_scaleZeroTransform, wmf_leftTransform)
    }
    var wmf_scaleZeroAndRightTransform: CATransform3D {
        return CATransform3DConcat(wmf_scaleZeroTransform, wmf_rightTransform)
    }
    var wmf_scaleZeroAndLowerLeftTransform: CATransform3D {
        return CATransform3DConcat(wmf_scaleZeroAndLeftTransform, wmf_lowerTransform)
    }
    var wmf_scaleZeroAndLowerRightTransform: CATransform3D {
          return CATransform3DConcat(wmf_scaleZeroAndRightTransform, wmf_lowerTransform)
    }
    
    open func beginAnimations() {
        
    }
    
    open func addAnimationElementsScaledToCurrentFrameSize() {
    
    }

    public var hasCircleBackground: Bool = false {
        didSet {
            if hasCircleBackground {
                backgroundColor = theme.colors.midBackground
                layer.masksToBounds = true
            } else {
                backgroundColor = .clear
                layer.masksToBounds = false
            }
            setNeedsLayout()
        }
    }

    var sizeAtLastAnimationElementAddition = CGSize.zero
    open override func layoutSubviews() {
        super.layoutSubviews()
        guard bounds.size != sizeAtLastAnimationElementAddition else {
            return
        }
        sizeAtLastAnimationElementAddition = bounds.size
        addAnimationElementsScaledToCurrentFrameSize()
        if hasCircleBackground {
            layer.cornerRadius = bounds.size.width / 2.0
        } else {
            layer.cornerRadius = 0
        }
    }
    
    open func removeExistingSubviewsAndSublayers() {
        for subview in subviews {
            subview.removeFromSuperview()
        }
        if let sublayers = layer.sublayers {
            for sublayer in sublayers {
                sublayer.removeFromSuperlayer()
            }
        }
    }
}
