import Foundation

extension UIView {
    @objc open func wmf_configureSubviewsForDynamicType() {
        for subview in subviews {
            subview.wmf_configureSubviewsForDynamicType()
        }
    }
}

extension UIButton {
    override open func wmf_configureSubviewsForDynamicType() {
        guard let titleLabel = titleLabel else {
            return
        }
        titleLabel.adjustsFontForContentSizeCategory = true
        super.wmf_configureSubviewsForDynamicType()
    }
}

extension UILabel {
    override open func wmf_configureSubviewsForDynamicType() {
        adjustsFontForContentSizeCategory = true
        super.wmf_configureSubviewsForDynamicType()
    }
}

extension UITextField {
    override open func wmf_configureSubviewsForDynamicType() {
         adjustsFontForContentSizeCategory = true
        super.wmf_configureSubviewsForDynamicType()
    }
}

