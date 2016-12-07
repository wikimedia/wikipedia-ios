import Foundation

extension UIButton {
    private func wmf_configureForDynamicType(){
        if #available(iOS 10.0, *) {
            self.titleLabel!.adjustsFontForContentSizeCategory = true
            self.titleLabel!.textAlignment = .Center
            self.titleLabel!.numberOfLines = 1
            self.titleLabel!.clipsToBounds = false
            self.titleLabel!.lineBreakMode = .ByWordWrapping
        }
    }
}

extension UILabel {
    private func wmf_configureForDynamicType(){
        if #available(iOS 10.0, *) {
            self.adjustsFontForContentSizeCategory = true
        }
    }
}

extension UIView {
    func wmf_configureSubviewsForDynamicType() {
        if #available(iOS 10.0, *) {
            if self.isKindOfClass(UIButton) {
                (self as! UIButton).wmf_configureForDynamicType()
            }else if self.isKindOfClass(UILabel) {
                (self as! UILabel).wmf_configureForDynamicType()
            }
            for subview in self.subviews {
                subview.wmf_configureSubviewsForDynamicType()
            }
        }
    }
}
