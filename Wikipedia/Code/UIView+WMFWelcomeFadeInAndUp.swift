
extension UIView {
    func wmf_zeroLayerOpacity() {
        layer.opacity = 0
    }

    func wmf_fadeInAndUpAfterDelay (delay: CGFloat) {
        layer.transform = CATransform3DMakeTranslation(0, 18, 0)
        UIView.animateWithDuration(
            0.4,
            delay: Double(delay),
            options: .CurveEaseInOut,
            animations: {
                self.layer.opacity = 1
                self.layer.transform = CATransform3DIdentity
            }, completion: nil)
    }
}
