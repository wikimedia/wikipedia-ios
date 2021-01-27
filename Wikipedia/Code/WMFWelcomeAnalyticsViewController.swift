
class WMFWelcomeAnalyticsViewController: ThemeableViewController {
    
    override func apply(theme: Theme) {
        super.apply(theme: theme)
        guard viewIfLoaded != nil else {
            return
        }
        toggle.onTintColor = theme.colors.accent
        learnMoreButton.setTitleColor(theme.colors.link, for: .normal)
    }
    
    @IBOutlet private var toggleLabel:UILabel!
    @IBOutlet private var toggleSubtitleLabel:UILabel!
    @IBOutlet private var toggle:UISwitch!

    @IBOutlet private var descriptionLabel:UILabel!
    @IBOutlet private var learnMoreButton:UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        descriptionLabel.text = WMFLocalizedString("welcome-send-data-sub-title", value:"Help improve the app by letting the Wikimedia Foundation know how you use it. Data collected is anonymous.", comment:"Sub-title explaining how sending usage reports can help improve the app")
        
        learnMoreButton.setTitle(WMFLocalizedString("welcome-send-data-learn-more", value:"Learn more about data collected", comment:"Text for link for learning more about opting-in to anonymous data collection"), for: .normal)
        
        toggleSubtitleLabel.text = WMFLocalizedString("welcome-volunteer-send-usage-reports", value:"Send usage reports", comment:"Text for switch allowing user to choose whether to send usage reports")
        
        updateToggleLabelTitleForUsageReportsIsOn(false)
        
        //Set state of the toggle. Also make sure crash manager setting is in sync with this setting - likely to happen on first launch or for previous users.
        let loggingEnabled = EventLoggingService.shared?.isEnabled ?? false
        if (loggingEnabled) {
            toggle.isOn = true
        } else {
            toggle.isOn = false
        }
        updateFonts()
        view.wmf_configureSubviewsForDynamicType()
    }
    
    private func updateToggleLabelTitleForUsageReportsIsOn(_ isOn: Bool) {
        //Hide accessibility of label because switch will become the label by default.
        toggleLabel.isAccessibilityElement = false
        
        toggleLabel.isHidden = !isOn
        toggle.accessibilityLabel = WMFLocalizedString("welcome-volunteer-send-usage-reports", value:"Send usage reports", comment:"Text for switch allowing user to choose whether to send usage reports")
    }
    
    @IBAction func toggleAnalytics(withSender sender: UISwitch){
        UserDefaults.standard.wmf_sendUsageReports = sender.isOn
        updateToggleLabelTitleForUsageReportsIsOn(sender.isOn)
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        updateFonts()
    }

    private func updateFonts() {
        learnMoreButton.titleLabel?.font = UIFont.wmf_font(.semiboldFootnote, compatibleWithTraitCollection: traitCollection)
    }

    @IBAction func showPrivacyAlert(withSender sender: AnyObject) {
        guard let url = URL.init(string: CommonStrings.privacyPolicyURLString) else {
            assertionFailure("Expected URL")
            return
        }
        navigate(to: url, useSafari: true)
    }
}
