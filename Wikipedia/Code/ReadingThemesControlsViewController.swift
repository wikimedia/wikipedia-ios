import UIKit

@objc public protocol WMFReadingThemesControlsViewControllerDelegate {
    
    func fontSizeSliderValueChangedInController(_ controller: ReadingThemesControlsViewController, value: Int)
}

@objc(WMFReadingThemesControlsViewController)
open class ReadingThemesControlsViewController: UIViewController {
    
    static let WMFUserDidSelectThemeNotification = "WMFUserDidSelectThemeNotification"
    static let WMFUserDidSelectThemeNotificationThemeKey = "theme"
    
    var theme = Theme.standard
    
    @IBOutlet weak var imageDimmingLabel: UILabel!
    @IBOutlet fileprivate var slider: SWStepSlider!
    fileprivate var maximumValue: Int?
    fileprivate var currentValue: Int?
    
    @IBOutlet weak var brightnessSlider: UISlider!
    
    @IBOutlet weak var lightThemeButton: UIButton!
    @IBOutlet weak var sepiaThemeButton: UIButton!
    @IBOutlet weak var darkThemeButton: UIButton!
    
    @IBOutlet weak var imageDimmingSwitch: ProminentSwitch!
    
    
    @IBOutlet var separatorViews: [UIView]!
    
    @IBOutlet var textSizeSliderViews: [UIView]!
    
    @IBOutlet weak var minBrightnessImageView: UIImageView!
    @IBOutlet weak var maxBrightnessImageView: UIImageView!
    
    @IBOutlet weak var tSmallImageView: UIImageView!
    @IBOutlet weak var tLargeImageView: UIImageView!
    
    @IBOutlet var textLabels: [UILabel]!
    @IBOutlet var stackView: UIStackView!
    
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
        
        imageDimmingLabel.text = CommonStrings.dimImagesTitle
        
        brightnessSlider.accessibilityLabel = WMFLocalizedString("reading-themes-controls-accessibility-brightness-slider", value: "Brightness slider", comment: "Accessibility label for the brightness slider in the Reading Themes Controls popover")
        lightThemeButton.accessibilityLabel = WMFLocalizedString("reading-themes-controls-accessibility-light-theme-button", value: "Light theme", comment: "Accessibility label for the light theme button in the Reading Themes Controls popover")
        sepiaThemeButton.accessibilityLabel = WMFLocalizedString("reading-themes-controls-accessibility-sepia-theme-button", value: "Sepia theme", comment: "Accessibility label for the sepia theme button in the Reading Themes Controls popover")
        darkThemeButton.accessibilityLabel = WMFLocalizedString("reading-themes-controls-accessibility-dark-theme-button", value: "Dark theme", comment: "Accessibility label for the dark theme button in the Reading Themes Controls popover")
        imageDimmingSwitch.accessibilityLabel = WMFLocalizedString("reading-themes-controls-accessibility-dim-images-switch", value: "Dim images", comment: "Accessibility label for the dim images switch in the Reading Themes Controls popover")
        
        for slideView in textSizeSliderViews {
            slideView.isAccessibilityElement = true
            slideView.accessibilityTraits = UIAccessibilityTraitAdjustable
            slideView.accessibilityLabel = WMFLocalizedString("reading-themes-controls-accessibility-text-size-slider", value: "Text size slider", comment: "Accessibility label for the text size slider in the Reading Themes Controls popover")
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.screenBrightnessChangedInApp(notification:)), name: NSNotification.Name.UIScreenBrightnessDidChange, object: nil)
        
        preferredContentSize = stackView.systemLayoutSizeFitting(UILayoutFittingCompressedSize)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        NSObject.cancelPreviousPerformRequests(withTarget: self)
    }
    
    func applyBorder(to button: UIButton) {
        button.borderWidth = 2
        button.isEnabled = false
        button.borderColor = theme.colors.link
        button.accessibilityTraits = UIAccessibilityTraitSelected
    }
    
    func removeBorderFrom(_ button: UIButton) {
        button.borderWidth = traitCollection.displayScale > 0.0 ? 1.0/traitCollection.displayScale : 0.5
        button.isEnabled = true
        button.borderColor = UIColor.wmf_lighterGray //intentionally unthemed
        button.accessibilityTraits = UIAccessibilityTraitButton
    }
    
    var isTextSizeSliderHidden: Bool {
        set {
            let _ = self.view //ensure view is loaded
            for slideView in textSizeSliderViews {
                slideView.isHidden = newValue
            }
            preferredContentSize = stackView.systemLayoutSizeFitting(UILayoutFittingCompressedSize)
        }
        get {
            return textSizeSliderViews.first?.isHidden ?? false
        }
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
    
    func applyImageDimmingChange(isOn: NSNumber) {
        let currentTheme = UserDefaults.wmf_userDefaults().wmf_appTheme
        UserDefaults.wmf_userDefaults().wmf_isImageDimmingEnabled = isOn.boolValue
        userDidSelect(theme: currentTheme.withDimmingEnabled(isOn.boolValue))
    }
    
    @IBAction func dimmingSwitchValueChanged(_ sender: UISwitch) {
        let selector = #selector(applyImageDimmingChange)
        NSObject.cancelPreviousPerformRequests(withTarget: self)
        perform(selector, with: NSNumber(value: sender.isOn), afterDelay: CATransaction.animationDuration())
    }
    
    override open func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        visible = true
        let currentTheme = UserDefaults.wmf_userDefaults().wmf_appTheme
        updateThemeButtons(with: currentTheme)
    }
    
    func updateThemeButtons(with theme: Theme) {
        removeBorderFrom(lightThemeButton)
        removeBorderFrom(darkThemeButton)
        removeBorderFrom(sepiaThemeButton)
        imageDimmingSwitch.isEnabled = false
        imageDimmingSwitch.isOn = UserDefaults.wmf_userDefaults().wmf_isImageDimmingEnabled
        switch theme.name {
        case Theme.sepia.name:
            applyBorder(to: sepiaThemeButton)
        case Theme.light.name:
            applyBorder(to: lightThemeButton)
        case Theme.darkDimmed.name:
            fallthrough
        case Theme.dark.name:
            imageDimmingSwitch.isEnabled = true
            applyBorder(to: darkThemeButton)
        default:
            break
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
    
    func userDidSelect(theme: Theme) {
        let userInfo = ["theme": theme]
        updateThemeButtons(with: theme)
        NotificationCenter.default.post(name: Notification.Name(ReadingThemesControlsViewController.WMFUserDidSelectThemeNotification), object: nil, userInfo: userInfo)
    }
    
    @IBAction func sepiaThemeButtonPressed(_ sender: Any) {
        userDidSelect(theme:  Theme.sepia)
    }
    
    @IBAction func lightThemeButtonPressed(_ sender: Any) {
        userDidSelect(theme: Theme.light)
    }
    
    @IBAction func darkThemeButtonPressed(_ sender: Any) {
        userDidSelect(theme: Theme.dark.withDimmingEnabled(UserDefaults.wmf_userDefaults().wmf_isImageDimmingEnabled))
    }
}

// MARK: - Themeable

extension ReadingThemesControlsViewController: Themeable {
    public func apply(theme: Theme) {
        self.theme = theme
        
        view.backgroundColor = theme.colors.popoverBackground
        
        for separator in separatorViews {
            separator.backgroundColor = theme.colors.border
        }
        
        slider.backgroundColor = view.backgroundColor
        
        for label in textLabels {
            label.textColor = theme.colors.primaryText
        }
        
        if (theme == Theme.light || theme == Theme.sepia) {
        textLabels.last?.textColor = UIColor.wmf_silver
        }
        
        let buttons = [lightThemeButton, darkThemeButton, sepiaThemeButton]
        for button in buttons {
            guard let button = button else {
                continue
            }
            button.borderColor = button.isEnabled ? theme.colors.border : theme.colors.link
        }


        minBrightnessImageView.tintColor = theme.colors.secondaryText
        maxBrightnessImageView.tintColor = theme.colors.secondaryText
        tSmallImageView.tintColor = theme.colors.secondaryText
        tLargeImageView.tintColor = theme.colors.secondaryText
        
        view.tintColor = theme.colors.link
    }
    
}
