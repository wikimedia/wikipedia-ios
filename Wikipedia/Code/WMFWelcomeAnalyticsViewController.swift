
class WMFWelcomeAnalyticsViewController: UIViewController {

    @IBOutlet fileprivate var toggleLabel:UILabel!
    @IBOutlet fileprivate var toggle:UISwitch!
    
    override func viewDidLoad() {
        super.viewDidLoad()
                
        updateToggleLabelTitleForUsageReportsIsOn(false)
        
        //Set state of the toggle. Also make sure crash manager setting is in sync with this setting - likely to happen on first launch or for previous users.
        if (UserDefaults.wmf_userDefaults().wmf_sendUsageReports()) {
            toggle.isOn = true
            BITHockeyManager.shared().crashManager.crashManagerStatus = .autoSend
        } else {
            toggle.isOn = false
            BITHockeyManager.shared().crashManager.crashManagerStatus = .alwaysAsk
        }
        self.view.wmf_configureSubviewsForDynamicType()
    }
    
    fileprivate func updateToggleLabelTitleForUsageReportsIsOn(_ isOn: Bool) {
        
        //Hide accessibility of label because switch will become the label by default.
        toggleLabel.isAccessibilityElement = false
        
        let title = isOn ? localizedStringForKeyFallingBackOnEnglish("welcome-volunteer-thanks").replacingOccurrences(of: "$1", with: "😀") : localizedStringForKeyFallingBackOnEnglish("welcome-volunteer-send-usage-reports")
        toggleLabel.text = title
        toggle.accessibilityLabel = localizedStringForKeyFallingBackOnEnglish("welcome-volunteer-send-usage-reports")
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
}
