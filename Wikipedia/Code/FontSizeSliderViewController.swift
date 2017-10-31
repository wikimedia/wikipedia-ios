import UIKit

@objc(WMFFontSizeSliderViewController)
class FontSizeSliderViewController: UIViewController {
    
    @IBOutlet weak var slider: StepSlider!
    
    @IBOutlet weak var tSmallImageView: UIImageView!
    @IBOutlet weak var tLargeImageView: UIImageView!
    
    fileprivate var maximumValue: Int?
    fileprivate var currentValue: Int?
    
    fileprivate var theme = Theme.standard
    
    @objc static let WMFArticleFontSizeMultiplierKey = "WMFArticleFontSizeMultiplier"
    @objc static let WMFArticleFontSizeUpdatedNotification = "WMFArticleFontSizeUpdatedNotification"
    
    let fontSizeMultipliers = [WMFFontSizeMultiplier.extraSmall, WMFFontSizeMultiplier.small, WMFFontSizeMultiplier.medium, WMFFontSizeMultiplier.large, WMFFontSizeMultiplier.extraLarge, WMFFontSizeMultiplier.extraExtraLarge, WMFFontSizeMultiplier.extraExtraExtraLarge]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let max = maximumValue {
            if let current = currentValue {
                setValues(0, maximum: max, current: current)
                maximumValue = nil
                currentValue = nil
            }
        }
        apply(theme: self.theme)
        slider.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setValuesWithSteps(fontSizeMultipliers.count, current: slider.indexOfCurrentFontSize())
    }
    
    func setValuesWithSteps(_ steps: Int, current: Int) {
        if self.isViewLoaded {
            setValues(0, maximum: steps - 1, current: current)
        } else {
            maximumValue = steps - 1
            currentValue = current
        }
    }
    
    func setValues(_ minimum: Int, maximum: Int, current: Int){
        slider.minimumValue = minimum
        slider.maximumValue = maximum
        slider.value = current
    }
    @IBAction func sliderValueChanged(_ sender: StepSlider) {
        let _ = setValue(slider.value)
    }
    
    func setValue(_ newValue: Int) -> Bool {
        if slider.value > fontSizeMultipliers.count {
            return false
        }
        
        let multiplier = fontSizeMultipliers[slider.value].rawValue
        let userInfo = [FontSizeSliderViewController.WMFArticleFontSizeMultiplierKey: multiplier]
        
        NotificationCenter.default.post(name: Notification.Name(FontSizeSliderViewController.WMFArticleFontSizeUpdatedNotification), object: nil, userInfo: userInfo)
        
        setValuesWithSteps(fontSizeMultipliers.count, current: slider.indexOfCurrentFontSize())
        return true
    }

}

extension FontSizeSliderViewController: Themeable {
    func apply(theme: Theme) {
        self.theme = theme
        
        guard viewIfLoaded != nil else {
            return
        }
        
        view.backgroundColor = theme.colors.midBackground
        slider.backgroundColor = theme.colors.midBackground
        tSmallImageView.tintColor = theme.colors.secondaryText
        tLargeImageView.tintColor = theme.colors.secondaryText
        
        if self.parent is AppearanceSettingsViewController {
            view.backgroundColor = theme.colors.paperBackground
            slider.backgroundColor = theme.colors.paperBackground
        }
    }
}

extension FontSizeSliderViewController: AccessibleSlider {
    func accessibilityIncrement() -> Int? {
        let newValue = slider.value + 1
        return setValue(newValue) ? newValue : nil
    }
    
    func accessibilityDecrement() -> Int? {
        let newValue = slider.value - 1
        return setValue(newValue) ? newValue : nil
    }
    
    
}
