import UIKit

@objc public protocol WMFReadingThemesControlsViewControllerDelegate {
    
    func fontSizeSliderValueChangedInController(_ controller: ReadingThemesControlsViewController, value: Int)
}

@objc(WMFReadingThemesControlsViewController)
open class ReadingThemesControlsViewController: UIViewController, AnalyticsContextProviding, AnalyticsContentTypeProviding {
    
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
    
    var steps: Int?
    
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
        
        lightThemeButton.backgroundColor = Theme.light.colors.paperBackground
        sepiaThemeButton.backgroundColor = Theme.sepia.colors.paperBackground
        darkThemeButton.backgroundColor = Theme.dark.colors.paperBackground
        
        lightThemeButton.setTitleColor(Theme.light.colors.primaryText, for: .normal)
        sepiaThemeButton.setTitleColor(Theme.sepia.colors.primaryText, for: .normal)
        darkThemeButton.setTitleColor(Theme.dark.colors.primaryText, for: .normal)
        
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
    
    open override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        let tap = UITapGestureRecognizer(target: self, action: #selector(self.handleTap(_:)))
        slider.addGestureRecognizer(tap)
    }
    
    func handleTap(_ sender: UIGestureRecognizer) {
        let pointTapped: CGPoint = sender.location(in: self.view)
        
        let positionOfSlider: CGPoint = slider.frame.origin
        let widthOfSlider: CGFloat = slider.frame.size.width
        let newValue = ((pointTapped.x - positionOfSlider.x) * CGFloat(slider.maximumValue) / widthOfSlider)
        
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        slider.value = Int(newValue)
        // Update UI without animation
        slider.setNeedsLayout()
        CATransaction.commit()
        
        
        
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
        self.steps = steps
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
        if (sender.isOn) {
        PiwikTracker.sharedInstance()?.wmf_logActionEnableImageDimming(inContext: self, contentType: self)
        } else {
        PiwikTracker.sharedInstance()?.wmf_logActionDisableImageDimming(inContext: self, contentType: self)
        }
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
    
    func screenBrightnessChangedInApp(notification: Notification){
        brightnessSlider.value = Float(UIScreen.main.brightness)
    }
    
    @IBAction func brightnessSliderValueChanged(_ sender: UISlider) {
        UIScreen.main.brightness = CGFloat(sender.value)
        PiwikTracker.sharedInstance()?.wmf_logActionAdjustBrightness(inContext: self, contentType: self)
    }
    
    @IBAction func fontSliderValueChanged(_ slider: SWStepSlider) {
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
        
        for label in textLabels {
            label.textColor = theme.colors.primaryText
        }
        
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
        imageDimmingLabel.textColor = imageDimmingSwitch.isEnabled ? theme.colors.primaryText : theme.colors.disabledText

        minBrightnessImageView.tintColor = theme.colors.secondaryText
        maxBrightnessImageView.tintColor = theme.colors.secondaryText
        tSmallImageView.tintColor = theme.colors.secondaryText
        tLargeImageView.tintColor = theme.colors.secondaryText
        
        view.tintColor = theme.colors.link
    }
    
}
