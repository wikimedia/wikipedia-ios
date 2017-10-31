import UIKit

protocol AccessibleSlider: NSObjectProtocol {
    func accessibilityIncrement() -> Int?
    func accessibilityDecrement() -> Int?
}

class StepSlider: SWStepSlider {
    
    weak var delegate: AccessibleSlider?
    
    let fontSizeMultipliers = [WMFFontSizeMultiplier.extraSmall, WMFFontSizeMultiplier.small, WMFFontSizeMultiplier.medium, WMFFontSizeMultiplier.large, WMFFontSizeMultiplier.extraLarge, WMFFontSizeMultiplier.extraExtraLarge, WMFFontSizeMultiplier.extraExtraExtraLarge]
    
    fileprivate var maxValue: Int?
    fileprivate var currentValue: Int?
    
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
    
    func didLoad() {
        if let max = maxValue {
            if let current = currentValue {
                setValues(0, maximum: max, current: current)
                maxValue = nil
                currentValue = nil
            }
        }
    }
    
    func willAppear() {
        setValuesWithSteps(fontSizeMultipliers.count, current: indexOfCurrentFontSize())
    }
    
    @objc public func setValuesWithSteps(_ steps: Int, current: Int) {
        if self.superview != nil {
            setValues(0, maximum: steps - 1, current: current)
        } else {
            maxValue = steps - 1
            currentValue = current
        }
    }
    
    func setValues(_ minimum: Int, maximum: Int, current: Int){
        minimumValue = minimum
        maximumValue = maximum
        value = current
    }
    
    func setValue(_ newValue: Int) -> Bool {
        guard let multiplier = fontSizeMultiplier(newValue) else {
            return false
        }
        
        let userInfo = [FontSizeSliderViewController.WMFArticleFontSizeMultiplierKey: multiplier]
        
        NotificationCenter.default.post(name: Notification.Name(FontSizeSliderViewController.WMFArticleFontSizeUpdatedNotification), object: nil, userInfo: userInfo)
        
        setValuesWithSteps(fontSizeMultipliers.count, current: indexOfCurrentFontSize())
        return true
    }
    
    func fontSizeMultiplier(_ newValue: Int) -> Int? {
        if newValue >= fontSizeMultipliers.count || newValue < 0 {
            return nil
        }
        
        return fontSizeMultipliers[newValue].rawValue
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
