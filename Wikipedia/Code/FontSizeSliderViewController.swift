import UIKit

class FontSizeSliderViewController: UIViewController {
    
    @IBOutlet fileprivate var slider: SWStepSlider!
    fileprivate var maximumValue: Int?
    fileprivate var currentValue: Int?
    
    static let WMFArticleFontSizeMultiplierKey = "WMFArticleFontSizeMultiplier"
    static let WMFArticleFontSizeUpdatedNotification = "WMFArticleFontSizeUpdatedNotification"
    
    let fontSizeMultipliers = [WMFFontSizeMultiplier.small, WMFFontSizeMultiplier.medium, WMFFontSizeMultiplier.large, WMFFontSizeMultiplier.extraSmall, WMFFontSizeMultiplier.extraLarge, WMFFontSizeMultiplier.extraExtraLarge, WMFFontSizeMultiplier.extraExtraExtraLarge]

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setValuesWithSteps(fontSizeMultipliers.count, current: indexOfCurrentFontSize())
        
        if let max = self.maximumValue {
            if let current = self.currentValue {
                self.setValues(0, maximum: max, current: current)
                self.maximumValue = nil
                self.currentValue = nil
            }
        }
    }

    func setValuesWithSteps(_ steps: Int, current: Int) {
        if self.isViewLoaded {
            self.setValues(0, maximum: steps-1, current: current)
        } else {
            maximumValue = steps-1
            currentValue = current
        }
    }
    
    func setValues(_ minimum: Int, maximum: Int, current: Int){
        self.slider.minimumValue = minimum
        self.slider.maximumValue = maximum
        self.slider.value = current
    }
    
    @IBAction func fontSliderValueChanged(_ slider: SWStepSlider) {
        print("fontSliderValueChanged")
        
        if slider.value > fontSizeMultipliers.count {
            return
        }
        let multiplier = fontSizeMultipliers[slider.value]
        
        let userInfo = [FontSizeSliderViewController.WMFArticleFontSizeMultiplierKey: multiplier]
        NotificationCenter.default.post(name: Notification.Name(FontSizeSliderViewController.WMFArticleFontSizeUpdatedNotification), object: nil, userInfo: userInfo)
    }
    
    func indexOfCurrentFontSize() -> Int {
        return UserDefaults.wmf_userDefaults().wmf_articleFontSizeMultiplier() as? Int ?? fontSizeMultipliers.count / 2
    }
    
//    func fontSizeMultipliers() -> [WMFFontSizeMultiplier] {
//        return [WMFFontSizeMultiplier.small, WMFFontSizeMultiplier.medium, WMFFontSizeMultiplier.large, WMFFontSizeMultiplier.extraSmall, WMFFontSizeMultiplier.extraLarge, WMFFontSizeMultiplier.extraExtraLarge, WMFFontSizeMultiplier.extraExtraExtraLarge]
//    }

}
