import UIKit

@objc(WMFFontSizeSliderViewController)
class FontSizeSliderViewController: UIViewController {
    
    @IBOutlet fileprivate var slider: SWStepSlider!
    fileprivate var maximumValue: Int?
    fileprivate var currentValue: Int?
    
    static let WMFArticleFontSizeMultiplierKey = "WMFArticleFontSizeMultiplier"
    static let WMFArticleFontSizeUpdatedNotification = "WMFArticleFontSizeUpdatedNotification"
    
    let fontSizeMultipliers = [WMFFontSizeMultiplier.small, WMFFontSizeMultiplier.medium, WMFFontSizeMultiplier.large, WMFFontSizeMultiplier.extraSmall, WMFFontSizeMultiplier.extraLarge, WMFFontSizeMultiplier.extraExtraLarge, WMFFontSizeMultiplier.extraExtraExtraLarge]

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
        print("fontSliderValueChanged")
        
        if slider.value > fontSizeMultipliers.count {
            print("will be returning :(")
            return
        }
        let multiplier = fontSizeMultipliers[slider.value].rawValue
        
        let userInfo = [FontSizeSliderViewController.WMFArticleFontSizeMultiplierKey: multiplier]
        NotificationCenter.default.post(name: Notification.Name(FontSizeSliderViewController.WMFArticleFontSizeUpdatedNotification), object: nil, userInfo: userInfo)
        print("after posting :)")

    }
    
    func indexOfCurrentFontSize() -> Int {
        //TODO: get from WMFArticleViewController
        return fontSizeMultipliers.count / 2
    }

}
