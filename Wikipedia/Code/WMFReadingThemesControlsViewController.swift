import UIKit

@objc public protocol WMFFontSliderViewControllerDelegate {
    
    func sliderValueChangedInController(_ controller: WMFReadingThemesControlsViewController, value: Int)
}

open class WMFReadingThemesControlsViewController: UIViewController {
    
    static let WMFUserDidSelectThemeNotification = "WMFUserDidSelectThemeNotification"
    
    @IBOutlet fileprivate var slider: SWStepSlider!
    fileprivate var maximumValue: Int?
    fileprivate var currentValue: Int?
    
    @IBOutlet weak var brightnessSlider: UISlider!
    
    @IBOutlet weak var standardThemeButton: UIButton!
    @IBOutlet weak var lightThemeButton: UIButton!
    @IBOutlet weak var darkThemeButton: UIButton!
    
    
    var visible = false
    
    open weak var fontSliderDelegate: WMFFontSliderViewControllerDelegate?
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        if let max = self.maximumValue {
            if let current = self.currentValue {
                self.setValues(0, maximum: max, current: current)
                self.maximumValue = nil
                self.currentValue = nil
            }
        }
        brightnessSlider.value = Float(UIScreen.main.brightness)

        
        
    }
    
    func applyBorder(to button: UIButton) {
        button.borderColor = UIColor.wmf_blue
        button.borderWidth = 2
    }
    
    func removeBorderFrom(_ button: UIButton) {
        button.borderWidth = 0
    }
    
    open func setValuesWithSteps(_ steps: Int, current: Int) {
        if self.isViewLoaded {
            self.setValues(0, maximum: steps-1, current: current)
        }else{
            maximumValue = steps-1
            currentValue = current
        }
    }
    
    func setValues(_ minimum: Int, maximum: Int, current: Int){
        self.slider.minimumValue = minimum
        self.slider.maximumValue = maximum
        self.slider.value = current
    }
    
    override open func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        visible = true
        
        let defaultThemeName = UserDefaults.wmf_userDefaults().string(forKey: "WMFAppThemeName")
        print("viewDidAppear WMFAppThemeName \(defaultThemeName)")
        
        if let name = defaultThemeName {
            switch name {
            case "standard":
                applyBorder(to: standardThemeButton)
            case "light":
                applyBorder(to: lightThemeButton)
            case "dark":
                applyBorder(to: darkThemeButton)
            default:
                break
            }
        }
    }
    
    
    @IBAction func brightnessSliderValueChanged(_ sender: UISlider) {
        UIScreen.main.brightness = CGFloat(sender.value)
    }
    
    @IBAction func fontSliderValueChanged(_ slider: SWStepSlider) {
        if let delegate = self.fontSliderDelegate, visible {
            delegate.sliderValueChangedInController(self, value: self.slider.value)
        }
    }
    
    @IBAction func changeThemeButtonPressed(_ sender: UIButton) {
        
        let defaultThemeName = UserDefaults.wmf_userDefaults().string(forKey: "WMFAppThemeName")
        print("changeThemeButtonPressed WMFAppThemeName \(defaultThemeName)")
        
        var theme = [String: Theme]()
        
        switch sender.tag {
        case 0:
            theme["theme"] = Theme.standard
            applyBorder(to: standardThemeButton)
            removeBorderFrom(lightThemeButton)
            removeBorderFrom(darkThemeButton)
        case 1:
            theme["theme"] = Theme.light
            applyBorder(to: lightThemeButton)
            removeBorderFrom(standardThemeButton)
            removeBorderFrom(darkThemeButton)
        case 2:
            theme["theme"] = Theme.dark
            applyBorder(to: darkThemeButton)
            removeBorderFrom(standardThemeButton)
            removeBorderFrom(lightThemeButton)
        default:
            break
        }
        
        NotificationCenter.default.post(name: Notification.Name(WMFReadingThemesControlsViewController.WMFUserDidSelectThemeNotification), object: nil, userInfo: theme)
        
        let newThemeName = UserDefaults.wmf_userDefaults().string(forKey: "WMFAppThemeName")
        print("after notification WMFAppThemeName \(newThemeName)")
        
        if let name = newThemeName {
            switch name {
            case "standard":
                applyBorder(to: standardThemeButton)
                removeBorderFrom(lightThemeButton)
                removeBorderFrom(darkThemeButton)
            case "light":
                applyBorder(to: lightThemeButton)
                removeBorderFrom(standardThemeButton)
                removeBorderFrom(darkThemeButton)
            case "dark":
                applyBorder(to: darkThemeButton)
                removeBorderFrom(standardThemeButton)
                removeBorderFrom(lightThemeButton)
            default:
                break
            }
        }
    }
}
