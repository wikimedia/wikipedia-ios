import UIKit

class StepSlider: SWStepSlider {
    
    weak var delegate: AccessibleSlider?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.isAccessibilityElement = true
        self.accessibilityTraits = UIAccessibilityTraitAdjustable
        self.accessibilityLabel = CommonStrings.textSizeSliderAccessibilityLabel
    }
    
    required public init?(coder: NSCoder) {
        super.init(coder: coder)
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
