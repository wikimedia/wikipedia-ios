import UIKit

@objc (WMFProminentSwitch)
class ProminentSwitch: UISwitch {
    override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = round(0.5*bounds.height)
    }
    
    override var isEnabled: Bool {
        didSet {
            backgroundColor = isEnabled ? nil : .base70
            tintColor = isEnabled ? nil : .base80
        }
    }
}
