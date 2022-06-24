import UIKit

class GroupedAccessibilityView: UIView {

    var arrangedAccessibilityViews: [UIView] = []
    
    // convienene outlets
    @IBOutlet weak var accessibilityView0: UIView?
    @IBOutlet weak var accessibilityView1: UIView?
    @IBOutlet weak var accessibilityView2: UIView?
    @IBOutlet weak var accessibilityView3: UIView?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        wmf_disableSubviewAccessibility()
        isAccessibilityElement = true
        accessibilityTraits = UIAccessibilityTraits.link
        
        guard let first = accessibilityView0 else {
            return
        }
        arrangedAccessibilityViews.append(first)
        
        guard let second = accessibilityView1 else {
            return
        }
        arrangedAccessibilityViews.append(second)
        
        guard let third = accessibilityView2 else {
            return
        }
        arrangedAccessibilityViews.append(third)
        
        guard let fourth = accessibilityView3 else {
            return
        }
        arrangedAccessibilityViews.append(fourth)
    }
    
    override var accessibilityLabel: String? {
        get {
            var combinedAccessibilityLabel = ""
            if let superLabel = super.accessibilityLabel {
                combinedAccessibilityLabel += superLabel + "\n"
            }
            for view in arrangedAccessibilityViews {
                guard let accessibilityLabel = view.accessibilityLabel else {
                    continue
                }
                combinedAccessibilityLabel += accessibilityLabel + "\n"
            }
            return combinedAccessibilityLabel
        }
        set {
            super.accessibilityLabel = newValue
        }
    }
    
}


extension UIView {

    func wmf_disableSubviewAccessibility() {
        for view in subviews {
            view.isAccessibilityElement = false
            view.wmf_disableSubviewAccessibility()
        }
    }
    
}
