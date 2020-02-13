import UIKit

protocol WMFReadingThemesControlsViewControllerDelegate: class {
    
    func fontSizeSliderValueChangedInController(_ controller: ReadingThemesControlsViewController, value: Int)
    func toggleSyntaxHighlighting(_ controller: ReadingThemesControlsViewController)
}

@objc(WMFReadingThemesControlsViewController)
class ReadingThemesControlsViewController: UIViewController {
    
    @objc static let WMFUserDidSelectThemeNotification = "WMFUserDidSelectThemeNotification"
    @objc static let WMFUserDidSelectThemeNotificationThemeNameKey = "themeName"
    @objc static let WMFUserDidSelectThemeNotificationIsImageDimmingEnabledKey = "isImageDimmingEnabled"
    @objc static let nibName = "ReadingThemesControlsViewController"
    
    var theme = Theme.standard
    
    @IBOutlet fileprivate var slider: SWStepSlider!
    fileprivate var maximumValue: Int?
    fileprivate var currentValue: Int?
    
    @IBOutlet weak var brightnessSlider: UISlider!
    
    @IBOutlet weak var lightThemeButton: UIButton!
    @IBOutlet weak var sepiaThemeButton: UIButton!
    @IBOutlet weak var darkThemeButton: UIButton!
    @IBOutlet weak var blackThemeButton: UIButton!

    @IBOutlet var separatorViews: [UIView]!
    
    @IBOutlet var textSizeSliderViews: [UIView]!
    
    @IBOutlet weak var minBrightnessImageView: UIImageView!
    @IBOutlet weak var maxBrightnessImageView: UIImageView!
    
    @IBOutlet weak var tSmallImageView: UIImageView!
    @IBOutlet weak var tLargeImageView: UIImageView!
    
    @IBOutlet var stackView: UIStackView!
    
    @IBOutlet var lastSeparator: UIView!
    @IBOutlet var syntaxHighlightingContainerView: UIView!
    @IBOutlet var syntaxHighlightingLabel: UILabel!
    @IBOutlet var syntaxHighlightingSwitch: UISwitch!

    var visible = false
    var showsSyntaxHighlighting: Bool = false {
        didSet {
            evaluateShowsSyntaxHighlightingState()
            updatePreferredContentSize()
        }
    }
    
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
        
        brightnessSlider.accessibilityLabel = WMFLocalizedString("reading-themes-controls-accessibility-brightness-slider", value: "Brightness slider", comment: "Accessibility label for the brightness slider in the Reading Themes Controls popover")
        lightThemeButton.accessibilityLabel = WMFLocalizedString("reading-themes-controls-accessibility-light-theme-button", value: "Light theme", comment: "Accessibility label for the light theme button in the Reading Themes Controls popover")
        sepiaThemeButton.accessibilityLabel = WMFLocalizedString("reading-themes-controls-accessibility-sepia-theme-button", value: "Sepia theme", comment: "Accessibility label for the sepia theme button in the Reading Themes Controls popover")
        darkThemeButton.accessibilityLabel = WMFLocalizedString("reading-themes-controls-accessibility-dark-theme-button", value: "Dark theme", comment: "Accessibility label for the dark theme button in the Reading Themes Controls popover")
        blackThemeButton.accessibilityLabel = WMFLocalizedString("reading-themes-controls-accessibility-black-theme-button", value: "Black theme", comment: "Accessibility label for the black theme button in the Reading Themes Controls popover")
        
        lightThemeButton.backgroundColor = Theme.light.colors.paperBackground
        sepiaThemeButton.backgroundColor = Theme.sepia.colors.paperBackground
        darkThemeButton.backgroundColor = Theme.dark.colors.paperBackground
        blackThemeButton.backgroundColor = Theme.black.colors.paperBackground
        
        lightThemeButton.setTitleColor(Theme.light.colors.primaryText, for: .normal)
        sepiaThemeButton.setTitleColor(Theme.sepia.colors.primaryText, for: .normal)
        darkThemeButton.setTitleColor(Theme.dark.colors.primaryText, for: .normal)
        blackThemeButton.setTitleColor(Theme.black.colors.primaryText, for: .normal)

        for slideView in textSizeSliderViews {
            slideView.accessibilityLabel = CommonStrings.textSizeSliderAccessibilityLabel
        }
        
        syntaxHighlightingLabel.text = WMFLocalizedString("reading-themes-controls-syntax-highlighting", value: "Syntax Highlighting", comment: "Text for syntax highlighting label in the Reading Themes Controls popover")
        syntaxHighlightingLabel.isAccessibilityElement = false
        syntaxHighlightingSwitch.accessibilityLabel = WMFLocalizedString("reading-themes-controls-accessibility-syntax-highlighting-switch", value: "Syntax Highlighting", comment: "Accessibility text for the syntax highlighting toggle in the Reading Themes Controls popover")
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.screenBrightnessChangedInApp(notification:)), name: UIScreen.brightnessDidChangeNotification, object: nil)

        updateFonts()
        evaluateShowsSyntaxHighlightingState()
        evaluateSyntaxHighlightingSelectedState()
        updatePreferredContentSize()
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
        button.accessibilityTraits = UIAccessibilityTraits.selected
    }
    
    func removeBorderFrom(_ button: UIButton) {
        button.borderWidth = traitCollection.displayScale > 0.0 ? 1.0/traitCollection.displayScale : 0.5
        button.isEnabled = true
        button.borderColor = theme.colors.border
        button.accessibilityTraits = UIAccessibilityTraits.button
    }
    
    var isTextSizeSliderHidden: Bool {
        set {
            let _ = self.view //ensure view is loaded
            for slideView in textSizeSliderViews {
                slideView.isHidden = newValue
            }
            updatePreferredContentSize()
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
        let currentTheme = UserDefaults.standard.theme(compatibleWith: traitCollection)
        apply(theme: currentTheme)
    }
    
    open override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        updateFonts()
    }

    private func updateFonts() {
        syntaxHighlightingLabel.font = UIFont.wmf_font(.body, compatibleWithTraitCollection: traitCollection)
    }
    
    @objc func screenBrightnessChangedInApp(notification: Notification){
        brightnessSlider.value = Float(UIScreen.main.brightness)
    }

    @objc fileprivate func _logBrightnessChange() {
    }

    fileprivate func logBrightnessChange() {
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(_logBrightnessChange), object: nil)
        self.perform(#selector(_logBrightnessChange), with: nil, afterDelay: 0.3, inModes: [RunLoop.Mode.default])
    }
    
    fileprivate func updatePreferredContentSize() {
        preferredContentSize = stackView.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
    }
    
    fileprivate func evaluateShowsSyntaxHighlightingState() {
        lastSeparator.isHidden = !showsSyntaxHighlighting
        syntaxHighlightingContainerView.isHidden = !showsSyntaxHighlighting
    }
    
    fileprivate func evaluateSyntaxHighlightingSelectedState() {
        syntaxHighlightingSwitch.isOn = UserDefaults.standard.wmf_IsSyntaxHighlightingEnabled
    }
    
    @IBAction func brightnessSliderValueChanged(_ sender: UISlider) {
        UIScreen.main.brightness = CGFloat(sender.value)
        logBrightnessChange()
    }
    
    @IBAction func fontSliderValueChanged(_ slider: SWStepSlider) {
        if let delegate = self.delegate, visible {
            delegate.fontSizeSliderValueChangedInController(self, value: self.slider.value)
        }
    }
    
    func userDidSelect(theme: Theme) {
        let userInfo = [ReadingThemesControlsViewController.WMFUserDidSelectThemeNotificationThemeNameKey: theme.name]
        NotificationCenter.default.post(name: Notification.Name(ReadingThemesControlsViewController.WMFUserDidSelectThemeNotification), object: nil, userInfo: userInfo)
    }
    
    @IBAction func sepiaThemeButtonPressed(_ sender: Any) {
        userDidSelect(theme:  Theme.sepia)
    }
    
    @IBAction func lightThemeButtonPressed(_ sender: Any) {
        userDidSelect(theme: Theme.light)
    }
    
    @IBAction func darkThemeButtonPressed(_ sender: Any) {
        userDidSelect(theme: Theme.dark.withDimmingEnabled(UserDefaults.standard.wmf_isImageDimmingEnabled))
    }

    @IBAction func blackThemeButtonPressed(_ sender: Any) {
        userDidSelect(theme: Theme.black.withDimmingEnabled(UserDefaults.standard.wmf_isImageDimmingEnabled))
    }
    @IBAction func syntaxHighlightingSwitched(_ sender: UISwitch) {
        delegate?.toggleSyntaxHighlighting(self)
        UserDefaults.standard.wmf_IsSyntaxHighlightingEnabled = sender.isOn
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
        removeBorderFrom(blackThemeButton)
        switch theme.name {
        case Theme.sepia.name:
            applyBorder(to: sepiaThemeButton)
        case Theme.light.name:
            applyBorder(to: lightThemeButton)
        case Theme.darkDimmed.name:
            fallthrough
        case Theme.dark.name:
            applyBorder(to: darkThemeButton)
        case Theme.blackDimmed.name:
            fallthrough
        case Theme.black.name:
            applyBorder(to: blackThemeButton)
        default:
            break
        }
        
        minBrightnessImageView.tintColor = theme.colors.secondaryText
        maxBrightnessImageView.tintColor = theme.colors.secondaryText
        tSmallImageView.tintColor = theme.colors.secondaryText
        tLargeImageView.tintColor = theme.colors.secondaryText
        
        syntaxHighlightingLabel.textColor = theme.colors.primaryText
        
        view.tintColor = theme.colors.link
    }
    
}
