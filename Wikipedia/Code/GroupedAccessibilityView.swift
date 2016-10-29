import UIKit

class GroupedAccessibilityView: UIView {
    
    override func awakeFromNib() {
        super.awakeFromNib()
        wmf_disableLabelAccesibility()
        isAccessibilityElement = true
        accessibilityTraits = UIAccessibilityTraitLink
    }
    
    override var accessibilityLabel: String? {
        get {
            return wmf_groupedAccessibilityLabel()
        }
        set {
            super.accessibilityLabel = newValue
        }
    }
    
}


extension UIView {
    
    func wmf_groupedAccessibilityLabel() -> String {
        var accessibilityLabel = ""
        for view in subviews {
            if let label = view as? UILabel, let text = label.text {
                accessibilityLabel += text + "\n"
            } else {
                accessibilityLabel += view.wmf_groupedAccessibilityLabel()
            }
        }
        return accessibilityLabel
    }
    
    func wmf_disableLabelAccesibility() {
        for view in subviews {
            if let label = view as? UILabel {
                label.isAccessibilityElement = false
            } else {
                view.wmf_disableLabelAccesibility()
            }
        }
    }
    
}
