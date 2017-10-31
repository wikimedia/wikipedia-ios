import UIKit

class StepSlider: SWStepSlider {
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.isAccessibilityElement = true
        self.accessibilityTraits = UIAccessibilityTraitAdjustable
        self.accessibilityLabel = CommonStrings.textSizeSliderAccessibilityLabel
    }
    
    required public init?(coder: NSCoder) {
        super.init(coder: coder)
    }
}
