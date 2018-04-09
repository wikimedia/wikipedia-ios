
extension UILabel {
    // Configure so text will shrink if translation string is crazy long.
    func wmf_configureToAutoAdjustFontSize(numberOfLines: Int = 1) {
        self.numberOfLines = numberOfLines
        adjustsFontSizeToFitWidth = true
        lineBreakMode = .byClipping
    }
}
