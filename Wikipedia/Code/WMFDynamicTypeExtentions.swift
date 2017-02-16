import Foundation

extension UIButton {
    fileprivate func wmf_configureForDynamicType(){
        if #available(iOS 10.0, *) {
            self.titleLabel!.adjustsFontForContentSizeCategory = true
            self.titleLabel!.textAlignment = .center
            self.titleLabel!.numberOfLines = 1
            self.titleLabel!.clipsToBounds = false
            self.titleLabel!.lineBreakMode = .byTruncatingTail
            self.titleLabel!.minimumScaleFactor = 0.25
            self.titleLabel!.adjustsFontSizeToFitWidth = true
        }
    }
}

extension UILabel {
    fileprivate func wmf_configureForDynamicType(){
        if #available(iOS 10.0, *) {
            self.adjustsFontForContentSizeCategory = true
        }
    }
}

extension UITextField {
    fileprivate func wmf_configureForDynamicType(){
        if #available(iOS 10.0, *) {
            self.adjustsFontForContentSizeCategory = true
        }
    }
}

extension UIView {
    func wmf_configureSubviewsForDynamicType() {
        if #available(iOS 10.0, *) {
            if self.isKind(of: UIButton.self) {
                (self as! UIButton).wmf_configureForDynamicType()
            }else if self.isKind(of: UILabel.self) {
                (self as! UILabel).wmf_configureForDynamicType()
            }else if self.isKind(of: UITextField.self) {
                (self as! UITextField).wmf_configureForDynamicType()
            }
            for subview in self.subviews {
                subview.wmf_configureSubviewsForDynamicType()
            }
        }
    }
}
