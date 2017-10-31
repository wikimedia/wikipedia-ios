import UIKit

protocol AccessibleSlider: NSObjectProtocol {
    func accessibilityIncrement() -> Int?
    func accessibilityDecrement() -> Int?
}

class StepSlider: SWStepSlider {
    
    weak var delegate: AccessibleSlider?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    func setup() {
        isAccessibilityElement = true
        accessibilityTraits = UIAccessibilityTraitAdjustable
        accessibilityLabel = CommonStrings.textSizeSliderAccessibilityLabel
    }
    
    // MARK: - Accessibility
    
    override open func accessibilityIncrement() {
        if let delegate = delegate {
            if let newValue = delegate.accessibilityIncrement() {
                self.value = newValue
                self.setNeedsLayout()
            }
        }
    }
    
    override open func accessibilityDecrement() {
        if let delegate = delegate {
            if let newValue = delegate.accessibilityDecrement() {
                self.value = newValue
                self.setNeedsLayout()
            }
        }
    }
}
