import Foundation

extension CGFloat {
    func wmf_denormalizeUsingReference (reference: CGFloat) -> CGFloat {
        return self * reference
    }
    func wmf_radiansFromDegrees() -> CGFloat{
        return ((self) / 180.0 * CGFloat(M_PI))
    }
}

extension CGPoint {
    func wmf_denormalizeUsingSize (size: CGSize) -> CGPoint {
        return CGPointMake(
            self.x.wmf_denormalizeUsingReference(size.width),
            self.y.wmf_denormalizeUsingReference(size.height)
        )
    }
}

extension CGSize {
    func wmf_denormalizeUsingSize (size: CGSize) -> CGSize {
        return CGSizeMake(
            self.width.wmf_denormalizeUsingReference(size.width),
            self.height.wmf_denormalizeUsingReference(size.height)
        )
    }
}

extension CGRect {
    func wmf_denormalizeUsingSize (size: CGSize) -> CGRect {
        let point = self.origin.wmf_denormalizeUsingSize(size)
        let size = self.size.wmf_denormalizeUsingSize(size)
        return CGRectMake(
            point.x,
            point.y,
            size.width,
            size.height
        )
    }
}

extension CALayer {
    public func wmf_animateToOpacity(opacity: Double, transform: CATransform3D, delay: Double, duration: Double){
        self.addAnimation(CABasicAnimation.wmf_animationToTransform(transform, delay: delay, duration: duration), forKey: nil)
        self.addAnimation(CABasicAnimation.wmf_animationToOpacity(opacity, delay: delay, duration: duration), forKey: nil)
    }
}

extension CABasicAnimation {
    class func wmf_animationToTransform(transform: CATransform3D, delay: Double, duration: Double) -> CABasicAnimation {
        let anim = CABasicAnimation(keyPath: "transform")
        anim.duration = duration
        anim.beginTime = CACurrentMediaTime() + delay
        anim.fillMode = kCAFillModeForwards
        anim.removedOnCompletion = false
        anim.toValue = NSValue(CATransform3D: transform)
        anim.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
        return anim;
    }
    class func wmf_animationToOpacity(opacity: Double, delay: Double, duration: Double) -> CABasicAnimation {
        let anim = CABasicAnimation(keyPath: "opacity")
        anim.duration = duration
        anim.beginTime = CACurrentMediaTime() + delay
        anim.fillMode = kCAFillModeForwards
        anim.removedOnCompletion = false
        anim.toValue = opacity
        anim.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
        return anim;
    }
}

extension CATransform3D {
    static func wmf_rotationTransformWithDegrees(degrees: CGFloat) -> CATransform3D {
        return CATransform3DMakeRotation(
            CGFloat(degrees).wmf_radiansFromDegrees(),
            0.0,
            0.0,
            1.0
        )
    }
}
