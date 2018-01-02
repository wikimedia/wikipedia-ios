import UIKit

extension UIView {
    @objc func wmf_enumerateSubviewTextFields(_ enumerator: (UITextField) -> Void) {
        for subview in subviews {
            if let textField = subview as? UITextField {
                enumerator(textField)
            }
            subview.wmf_enumerateSubviewTextFields(enumerator)
        }
    }
}
