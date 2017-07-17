import UIKit

@objc public protocol WMFReadingThemesControlsViewControllerDelegate {
    
    func fontSizeSliderValueChangedInController(_ controller: WMFReadingThemesControlsViewController, value: Int)
}

open class WMFReadingThemesControlsViewController: UIViewController {
    
    static let WMFUserDidSelectThemeNotification = "WMFUserDidSelectThemeNotification"
    
    var theme: Theme?
    
    @IBOutlet fileprivate var slider: SWStepSlider!
    fileprivate var maximumValue: Int?
    fileprivate var currentValue: Int?
    
    @IBOutlet weak var brightnessSlider: UISlider!
    
    @IBOutlet weak var lightThemeButton: UIButton!
    @IBOutlet weak var sepiaThemeButton: UIButton!
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
        autoNightModeSwitch.isEnabled = false
        imageDimmingSwitch.isEnabled = false
    }
    
    func applyBorder(to button: UIButton) {
        button.borderColor = UIColor.wmf_blue
        button.borderWidth = 2
        button.isEnabled = false
    }
    
    func removeBorderFrom(_ button: UIButton) {
        button.borderWidth = 0
        button.isEnabled = true
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
        let currentThemeName = UserDefaults.wmf_userDefaults().wmf_appThemeName ?? Theme.light.name
        updateThemeButtons(with: currentThemeName)
    }
    
    func updateThemeButtons(with currentThemeName: String) {
        removeBorderFrom(lightThemeButton)
        removeBorderFrom(darkThemeButton)
        removeBorderFrom(sepiaThemeButton)
        switch currentThemeName {
        case Theme.sepia.name:
            applyBorder(to: sepiaThemeButton)
        case Theme.light.name:
            applyBorder(to: lightThemeButton)
        case Theme.dark.name:
            applyBorder(to: darkThemeButton)
        default:
            break
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
    
    func userDidSelect(theme: Theme) {
        let userInfo = ["theme": theme]
        updateThemeButtons(with: theme.name)
        NotificationCenter.default.post(name: Notification.Name(WMFReadingThemesControlsViewController.WMFUserDidSelectThemeNotification), object: nil, userInfo: userInfo)
    }
    
    @IBAction func sepiaThemeButtonPressed(_ sender: Any) {
       userDidSelect(theme: Theme.sepia)
    }
    
    @IBAction func lightThemeButtonPressed(_ sender: Any) {
        userDidSelect(theme: Theme.light)
    }
    
    @IBAction func darkThemeButtonPressed(_ sender: Any) {
        userDidSelect(theme: Theme.dark)
    }
}

// MARK: - Themeable

extension WMFReadingThemesControlsViewController: Themeable {
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
