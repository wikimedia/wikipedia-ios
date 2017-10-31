import UIKit

@objc public protocol WMFReadingThemesControlsViewControllerDelegate {
    
    func fontSizeSliderValueChangedInController(_ controller: ReadingThemesControlsViewController, value: Int)
}

@objc(WMFReadingThemesControlsViewController)
open class ReadingThemesControlsViewController: UIViewController, AnalyticsContextProviding, AnalyticsContentTypeProviding {
    
    @objc static let WMFUserDidSelectThemeNotification = "WMFUserDidSelectThemeNotification"
    @objc static let WMFUserDidSelectThemeNotificationThemeKey = "theme"
    
    var theme = Theme.standard
    

    @IBOutlet weak var slider: StepSlider!
    fileprivate var maximumValue: Int?
    fileprivate var currentValue: Int?
    
    @IBOutlet weak var brightnessSlider: UISlider!
    
    @IBOutlet weak var lightThemeButton: UIButton!
    @IBOutlet weak var sepiaThemeButton: UIButton!
    @IBOutlet weak var darkThemeButton: UIButton!
    
    @IBOutlet var separatorViews: [UIView]!
    
    @IBOutlet var textSizeSliderViews: [UIView]!
    
    @IBOutlet weak var minBrightnessImageView: UIImageView!
    @IBOutlet weak var maxBrightnessImageView: UIImageView!
    
    @IBOutlet weak var tSmallImageView: UIImageView!
    @IBOutlet weak var tLargeImageView: UIImageView!
    
    @IBOutlet var stackView: UIStackView!
    
    var visible = false
    
    @objc open weak var delegate: WMFReadingThemesControlsViewControllerDelegate?
    
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
        
        brightnessSlider.accessibilityLabel = WMFLocalizedString("reading-themes-controls-accessibility-brightness-slider", value: "Brightness slider", comment: "Accessibility label for the brightness slider in the Reading Themes Controls popover")
        lightThemeButton.accessibilityLabel = WMFLocalizedString("reading-themes-controls-accessibility-light-theme-button", value: "Light theme", comment: "Accessibility label for the light theme button in the Reading Themes Controls popover")
        sepiaThemeButton.accessibilityLabel = WMFLocalizedString("reading-themes-controls-accessibility-sepia-theme-button", value: "Sepia theme", comment: "Accessibility label for the sepia theme button in the Reading Themes Controls popover")
        darkThemeButton.accessibilityLabel = WMFLocalizedString("reading-themes-controls-accessibility-dark-theme-button", value: "Dark theme", comment: "Accessibility label for the dark theme button in the Reading Themes Controls popover")
        
        lightThemeButton.backgroundColor = Theme.light.colors.paperBackground
        sepiaThemeButton.backgroundColor = Theme.sepia.colors.paperBackground
        darkThemeButton.backgroundColor = Theme.dark.colors.paperBackground
        
        lightThemeButton.setTitleColor(Theme.light.colors.primaryText, for: .normal)
        sepiaThemeButton.setTitleColor(Theme.sepia.colors.primaryText, for: .normal)
        darkThemeButton.setTitleColor(Theme.dark.colors.primaryText, for: .normal)
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.screenBrightnessChangedInApp(notification:)), name: NSNotification.Name.UIScreenBrightnessDidChange, object: nil)
        
        preferredContentSize = stackView.systemLayoutSizeFitting(UILayoutFittingCompressedSize)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        NSObject.cancelPreviousPerformRequests(withTarget: self)
    }
    
    open override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
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
    
    @objc open func setValuesWithSteps(_ steps: Int, current: Int) {
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
    
    override open func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        visible = true
        let currentTheme = UserDefaults.wmf_userDefaults().wmf_appTheme
        apply(theme: currentTheme)
    }
    
    public var analyticsContext: String {
        return "Article"
    }
    
    public var analyticsContentType: String {
        return "Article"
    }
    
    @objc func screenBrightnessChangedInApp(notification: Notification){
        brightnessSlider.value = Float(UIScreen.main.brightness)
    }

    @objc fileprivate func _logBrightnessChange() {
        PiwikTracker.sharedInstance()?.wmf_logActionAdjustBrightness(inContext: self, contentType: self)
    }

    fileprivate func logBrightnessChange() {
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(_logBrightnessChange), object: nil)
        self.perform(#selector(_logBrightnessChange), with: nil, afterDelay: 0.3, inModes: [.defaultRunLoopMode])
    }
    
    @IBAction func brightnessSliderValueChanged(_ sender: UISlider) {
        UIScreen.main.brightness = CGFloat(sender.value)
        logBrightnessChange()
    }
    
    @IBAction func fontSliderValueChanged(_ sender: StepSlider) {
        if let delegate = self.delegate, visible {
            delegate.fontSizeSliderValueChangedInController(self, value: self.slider.value)
        }
    }
    
    func userDidSelect(theme: Theme) {
        let userInfo = ["theme": theme]
        NotificationCenter.default.post(name: Notification.Name(ReadingThemesControlsViewController.WMFUserDidSelectThemeNotification), object: nil, userInfo: userInfo)
        PiwikTracker.sharedInstance()?.wmf_logActionSwitchTheme(inContext: self, contentType: AnalyticsContent(theme.displayName))
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
        
        removeBorderFrom(lightThemeButton)
        removeBorderFrom(darkThemeButton)
        removeBorderFrom(sepiaThemeButton)
        switch theme.name {
        case Theme.sepia.name:
            applyBorder(to: sepiaThemeButton)
        case Theme.light.name:
            applyBorder(to: lightThemeButton)
        case Theme.darkDimmed.name:
            fallthrough
        case Theme.dark.name:
            applyBorder(to: darkThemeButton)
        default:
            break
        }
        
        minBrightnessImageView.tintColor = theme.colors.secondaryText
        maxBrightnessImageView.tintColor = theme.colors.secondaryText
        tSmallImageView.tintColor = theme.colors.secondaryText
        tLargeImageView.tintColor = theme.colors.secondaryText
        
        view.tintColor = theme.colors.link
    }
    
}
