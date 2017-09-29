
class WMFWelcomeAnalyticsViewController: UIViewController {

    @IBOutlet fileprivate var toggleLabel:UILabel!
    @IBOutlet fileprivate var toggleSubtitleLabel:UILabel!
    @IBOutlet fileprivate var toggle:UISwitch!
    @IBOutlet fileprivate var getStartedButton:UIButton!

    @IBOutlet fileprivate var descriptionLabel:UILabel!
    @IBOutlet fileprivate var linkLabel:UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // TODO: figure out how to make this color public - naming and such (it's in the theme colors)
        toggle.onTintColor = UIColor(0x00AF89)
        
        descriptionLabel.text = WMFLocalizedString("welcome-send-data-sub-title", value:"Help improve the app by letting the Wikimedia Foundation know how you use it. Data collected is anonymous.", comment:"Sub-title explaining how sending usage reports can help improve the app")
        
        // TODO: hook up this to alert once we get strings for it.
        linkLabel.text = WMFLocalizedString("welcome-send-data-learn-more", value:"Learn more about data collected", comment:"Text for link for learning more about opting-in to anonymous data collection")
        
        linkLabel.textColor = .wmf_blue
        
        toggleSubtitleLabel.text = WMFLocalizedString("welcome-volunteer-send-usage-reports", value:"Send usage reports", comment:"Text for switch allowing user to choose whether to send usage reports")

        getStartedButton.setTitle(WMFLocalizedString("welcome-explore-continue-button", value:"Get started", comment:"Text for button for dismissing welcome screens\n{{Identical|Get started}}"), for: .normal)
        getStartedButton.backgroundColor = .wmf_blue
        
        updateToggleLabelTitleForUsageReportsIsOn(false)
        
        //Set state of the toggle. Also make sure crash manager setting is in sync with this setting - likely to happen on first launch or for previous users.
        if (UserDefaults.wmf_userDefaults().wmf_sendUsageReports()) {
            toggle.isOn = true
            BITHockeyManager.shared().crashManager.crashManagerStatus = .autoSend
        } else {
            toggle.isOn = false
            BITHockeyManager.shared().crashManager.crashManagerStatus = .alwaysAsk
        }
        view.wmf_configureSubviewsForDynamicType()
    }
    
    fileprivate func updateToggleLabelTitleForUsageReportsIsOn(_ isOn: Bool) {
        //Hide accessibility of label because switch will become the label by default.
        toggleLabel.isAccessibilityElement = false
        
        toggleLabel.isHidden = !isOn
        toggle.accessibilityLabel = WMFLocalizedString("welcome-volunteer-send-usage-reports", value:"Send usage reports", comment:"Text for switch allowing user to choose whether to send usage reports")
    }
    
    @IBAction func toggleAnalytics(withSender sender: UISwitch){
        if(sender.isOn){
            BITHockeyManager.shared().crashManager.crashManagerStatus = .autoSend
            UserDefaults.wmf_userDefaults().wmf_setSendUsageReports(true)
        }else{
            BITHockeyManager.shared().crashManager.crashManagerStatus = .alwaysAsk
            UserDefaults.wmf_userDefaults().wmf_setSendUsageReports(false)
        }
        updateToggleLabelTitleForUsageReportsIsOn(sender.isOn)
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        linkLabel.font = UIFont.wmf_preferredFontForFontFamily(.systemBold, withTextStyle: .footnote, compatibleWithTraitCollection: traitCollection)
    }
}
