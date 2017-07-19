import UIKit

@objc(WMFFontSizeSliderViewController)
class FontSizeSliderViewController: UIViewController {
    
    @IBOutlet fileprivate var slider: SWStepSlider!
    fileprivate var maximumValue: Int?
    fileprivate var currentValue: Int?
    
    static let WMFArticleFontSizeMultiplierKey = "WMFArticleFontSizeMultiplier"
    static let WMFArticleFontSizeUpdatedNotification = "WMFArticleFontSizeUpdatedNotification"
    
    let fontSizeMultipliers = [WMFFontSizeMultiplier.extraSmall, WMFFontSizeMultiplier.small, WMFFontSizeMultiplier.medium, WMFFontSizeMultiplier.large, WMFFontSizeMultiplier.extraLarge, WMFFontSizeMultiplier.extraExtraLarge, WMFFontSizeMultiplier.extraExtraExtraLarge]

    override func viewDidLoad() {
        super.viewDidLoad()
    
        if let max = self.maximumValue {
            if let current = self.currentValue {
                self.setValues(0, maximum: max, current: current)
                self.maximumValue = nil
                self.currentValue = nil
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setValuesWithSteps(fontSizeMultipliers.count, current: indexOfCurrentFontSize())
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
        if slider.value > fontSizeMultipliers.count {
            return
        }
        let multiplier = fontSizeMultipliers[slider.value].rawValue
        
        let userInfo = [FontSizeSliderViewController.WMFArticleFontSizeMultiplierKey: multiplier]
        NotificationCenter.default.post(name: Notification.Name(FontSizeSliderViewController.WMFArticleFontSizeUpdatedNotification), object: nil, userInfo: userInfo)
        
        setValuesWithSteps(fontSizeMultipliers.count, current: indexOfCurrentFontSize())

    }
    
    func indexOfCurrentFontSize() -> Int {
        if let fontSize = UserDefaults.wmf_userDefaults().wmf_articleFontSizeMultiplier() as? Int, let multiplier = WMFFontSizeMultiplier(rawValue: fontSize) {
            return fontSizeMultipliers.index(of: multiplier)!
        }
        return fontSizeMultipliers.count / 2
    }

}
