import UIKit

protocol AccessibleSlider: NSObjectProtocol {
    func accessibilityIncrement() -> Int?
    func accessibilityDecrement() -> Int?
}

class StepSlider: SWStepSlider {
    
    weak var delegate: AccessibleSlider?
    
    let fontSizeMultipliers = [WMFFontSizeMultiplier.extraSmall, WMFFontSizeMultiplier.small, WMFFontSizeMultiplier.medium, WMFFontSizeMultiplier.large, WMFFontSizeMultiplier.extraLarge, WMFFontSizeMultiplier.extraExtraLarge, WMFFontSizeMultiplier.extraExtraExtraLarge]
    
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
    
    func indexOfCurrentFontSize() -> Int {
        if let fontSize = UserDefaults.wmf_userDefaults().wmf_articleFontSizeMultiplier() as? Int, let multiplier = WMFFontSizeMultiplier(rawValue: fontSize) {
            return fontSizeMultipliers.index(of: multiplier)!
        }
        return fontSizeMultipliers.count / 2
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
