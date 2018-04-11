
extension UILabel {
    // Configure so text will shrink if translation string is crazy long.
    func wmf_configureToAutoAdjustFontSize() {
        self.numberOfLines = 1
        adjustsFontSizeToFitWidth = true
        lineBreakMode = .byClipping
    }
}
