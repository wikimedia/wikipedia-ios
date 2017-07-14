import UIKit

@objc public protocol WMFReadingThemesControlsViewControllerDelegate {
    
    func fontSizeSliderValueChangedInController(_ controller: WMFReadingThemesControlsViewController, value: Int)
}

open class WMFReadingThemesControlsViewController: UIViewController {
    
    static let WMFUserDidSelectThemeNotification = "WMFUserDidSelectThemeNotification"
    
    fileprivate var theme = Theme.standard
    
    @IBOutlet fileprivate var slider: SWStepSlider!
    fileprivate var maximumValue: Int?
    fileprivate var currentValue: Int?
    
    @IBOutlet weak var brightnessSlider: UISlider!
    
    @IBOutlet weak var standardThemeButton: UIButton!
    @IBOutlet weak var lightThemeButton: UIButton!
    @IBOutlet weak var darkThemeButton: UIButton!
    
    
    var visible = false
    
    open weak var delegate: WMFReadingThemesControlsViewControllerDelegate?
    
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
        
        // TODO: Enable when theme is implemented
        lightThemeButton.isEnabled = false
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
        
        if let name = UserDefaults.wmf_userDefaults().string(forKey: "WMFAppThemeName") {
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
        if let delegate = self.delegate, visible {
            delegate.fontSizeSliderValueChangedInController(self, value: self.slider.value)
        }
    }
    
    @IBAction func standardThemeButtonPressed(_ sender: Any) {
        let theme = ["theme": Theme.standard]
        
        applyBorder(to: standardThemeButton)
        removeBorderFrom(lightThemeButton)
        removeBorderFrom(darkThemeButton)
        
        NotificationCenter.default.post(name: Notification.Name(WMFReadingThemesControlsViewController.WMFUserDidSelectThemeNotification), object: nil, userInfo: theme)
    }
    
    @IBAction func lightThemeButtonPressed(_ sender: Any) {
        let theme = ["theme": Theme.light]
        
        applyBorder(to: lightThemeButton)
        removeBorderFrom(standardThemeButton)
        removeBorderFrom(darkThemeButton)
        
        NotificationCenter.default.post(name: Notification.Name(WMFReadingThemesControlsViewController.WMFUserDidSelectThemeNotification), object: nil, userInfo: theme)
    }
    
    @IBAction func darkThemeButtonPressed(_ sender: Any) {
        let theme = ["theme": Theme.dark]
        
        applyBorder(to: darkThemeButton)
        removeBorderFrom(standardThemeButton)
        removeBorderFrom(lightThemeButton)
        
        NotificationCenter.default.post(name: Notification.Name(WMFReadingThemesControlsViewController.WMFUserDidSelectThemeNotification), object: nil, userInfo: theme)
    }
    
}

// MARK: - Themeable

extension WMFReadingThemesControlsViewController: Themeable {
    public func apply(theme: Theme) {
        self.theme = theme
        guard viewIfLoaded != nil else {
            return
        }
        
        //TODO: apply colors when theme work is merged
    }
    
}
