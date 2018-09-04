
extension UIView {
    func wmf_zeroLayerOpacity() {
        layer.opacity = 0
    }

    func wmf_fadeInAndUpWithDuration (_ duration: Double, delay: Double) {
        layer.transform = CATransform3DMakeTranslation(0, 18, 0)
        UIView.animate(
            withDuration: duration,
            delay: delay,
            options: UIView.AnimationOptions(),
            animations: {
                self.layer.opacity = 1
                self.layer.transform = CATransform3DIdentity
            }, completion: nil)
    }
}
