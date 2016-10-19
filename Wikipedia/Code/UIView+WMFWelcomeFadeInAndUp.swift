
extension UIView {
    func wmf_zeroLayerOpacity() {
        layer.opacity = 0
    }

    func wmf_fadeInAndUpWithDuration (duration: Double, delay: Double) {
        layer.transform = CATransform3DMakeTranslation(0, 18, 0)
        UIView.animateWithDuration(
            duration,
            delay: delay,
            options: .CurveEaseInOut,
            animations: {
                self.layer.opacity = 1
                self.layer.transform = CATransform3DIdentity
            }, completion: nil)
    }
}
