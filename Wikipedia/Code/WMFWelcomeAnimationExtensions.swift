import Foundation

extension CGFloat {
    func wmf_denormalizeUsingReference (_ reference: CGFloat) -> CGFloat {
        return self * reference
    }
    func wmf_radiansFromDegrees() -> CGFloat{
        return ((self) / 180.0 * CGFloat(Double.pi))
    }
}

extension CGPoint {
    func wmf_denormalizeUsingSize (_ size: CGSize) -> CGPoint {
        return CGPoint(
            x: self.x.wmf_denormalizeUsingReference(size.width),
            y: self.y.wmf_denormalizeUsingReference(size.height)
        )
    }
}

extension CGSize {
    func wmf_denormalizeUsingSize (_ size: CGSize) -> CGSize {
        return CGSize(
            width: self.width.wmf_denormalizeUsingReference(size.width),
            height: self.height.wmf_denormalizeUsingReference(size.height)
        )
    }
}

extension CGRect {
    func wmf_denormalizeUsingSize (_ size: CGSize) -> CGRect {
        let point = self.origin.wmf_denormalizeUsingSize(size)
        let size = self.size.wmf_denormalizeUsingSize(size)
        return CGRect(
            x: point.x,
            y: point.y,
            width: size.width,
            height: size.height
        )
    }
}

extension CALayer {
    public func wmf_animateToOpacity(_ opacity: Double, transform: CATransform3D, delay: Double, duration: Double){
        self.add(CABasicAnimation.wmf_animationToTransform(transform, delay: delay, duration: duration), forKey: nil)
        self.add(CABasicAnimation.wmf_animationToOpacity(opacity, delay: delay, duration: duration), forKey: nil)
    }
}

extension CABasicAnimation {
    class func wmf_animationToTransform(_ transform: CATransform3D, delay: Double, duration: Double) -> CABasicAnimation {
        let anim = CABasicAnimation(keyPath: "transform")
        anim.duration = duration
        anim.beginTime = CACurrentMediaTime() + delay
        anim.fillMode = kCAFillModeForwards
        anim.isRemovedOnCompletion = false
        anim.toValue = NSValue(caTransform3D: transform)
        anim.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
        return anim;
    }
    class func wmf_animationToOpacity(_ opacity: Double, delay: Double, duration: Double) -> CABasicAnimation {
        let anim = CABasicAnimation(keyPath: "opacity")
        anim.duration = duration
        anim.beginTime = CACurrentMediaTime() + delay
        anim.fillMode = kCAFillModeForwards
        anim.isRemovedOnCompletion = false
        anim.toValue = opacity
        anim.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
        return anim;
    }
}

extension CATransform3D {
    static func wmf_rotationTransformWithDegrees(_ degrees: CGFloat) -> CATransform3D {
        return CATransform3DMakeRotation(
            CGFloat(degrees).wmf_radiansFromDegrees(),
            0.0,
            0.0,
            1.0
        )
    }
}
