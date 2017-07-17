import UIKit

@objc public protocol WMFReadingThemesControlsViewControllerDelegate {
    
    func fontSizeSliderValueChangedInController(_ controller: ReadingThemesControlsViewController, value: Int)
}

@objc(WMFReadingThemesControlsViewController)
open class ReadingThemesControlsViewController: UIViewController {
    
    static let WMFUserDidSelectThemeNotification = "WMFUserDidSelectThemeNotification"
    
    var theme: Theme?
    
    @IBOutlet fileprivate var slider: SWStepSlider!
    fileprivate var maximumValue: Int?
    fileprivate var currentValue: Int?
    
    @IBOutlet weak var brightnessSlider: UISlider!
    
    @IBOutlet weak var standardThemeButton: UIButton!
    @IBOutlet weak var lightThemeButton: UIButton!
    @IBOutlet weak var darkThemeButton: UIButton!
    
    @IBOutlet weak var autoNightModeSwitch: UISwitch!
    @IBOutlet weak var imageDimmingSwitch: UISwitch!
    
    @IBOutlet var separatorViews: [UIView]!
    
    @IBOutlet weak var minBrightnessImageView: UIImageView!
    @IBOutlet weak var maxBrightnessImageView: UIImageView!
    
    @IBOutlet weak var tSmallImageView: UIImageView!
    @IBOutlet weak var tLargeImageView: UIImageView!
    
    @IBOutlet var textLabels: [UILabel]!
    
    
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
        
        // TODO: Enable when implemented
        lightThemeButton.isEnabled = false
        
        autoNightModeSwitch.isEnabled = false
        imageDimmingSwitch.isEnabled = false
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.screenBrightnessChangedInApp(notification:)), name: NSNotification.Name.UIScreenBrightnessDidChange, object: nil)
        
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
    
    func screenBrightnessChangedInApp(notification: Notification){
        brightnessSlider.value = Float(UIScreen.main.brightness)
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
        
        NotificationCenter.default.post(name: Notification.Name(ReadingThemesControlsViewController.WMFUserDidSelectThemeNotification), object: nil, userInfo: theme)
    }
    
    @IBAction func lightThemeButtonPressed(_ sender: Any) {
        let theme = ["theme": Theme.light]
        
        applyBorder(to: lightThemeButton)
        removeBorderFrom(standardThemeButton)
        removeBorderFrom(darkThemeButton)
        
        NotificationCenter.default.post(name: Notification.Name(ReadingThemesControlsViewController.WMFUserDidSelectThemeNotification), object: nil, userInfo: theme)
    }
    
    @IBAction func darkThemeButtonPressed(_ sender: Any) {
        let theme = ["theme": Theme.dark]
        
        applyBorder(to: darkThemeButton)
        removeBorderFrom(standardThemeButton)
        removeBorderFrom(lightThemeButton)
        
        NotificationCenter.default.post(name: Notification.Name(ReadingThemesControlsViewController.WMFUserDidSelectThemeNotification), object: nil, userInfo: theme)
    }
    
}

// MARK: - Themeable

extension ReadingThemesControlsViewController: Themeable {
    public func apply(theme: Theme) {
        self.theme = theme
        
        view.backgroundColor = theme.colors.midBackground
        
        for separator in separatorViews {
            separator.backgroundColor = theme.colors.baseBackground
        }
        
        slider.backgroundColor = theme.colors.midBackground
        
        for label in textLabels {
            label.textColor = theme.colors.primaryText
        }
        
        if theme.name == "dark" {
            minBrightnessImageView.image = UIImage(named: "minBrightness-darkMode")
            maxBrightnessImageView.image = UIImage(named: "maxBrightness-darkMode")
            tSmallImageView.image = UIImage(named: "t-small-darkMode")
            tLargeImageView.image = UIImage(named: "t-large-darkMode")
        }
        
    }
    
}
