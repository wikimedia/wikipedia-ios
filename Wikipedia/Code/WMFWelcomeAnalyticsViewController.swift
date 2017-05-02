
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
        
        let title = isOn ? NSLocalizedString("welcome-volunteer-thanks", value:"%1$@ Thank you!", comment:"Text which is shown if the user decides to send usage reports. %1$@ will be substituted with a positive image or emoji such as a smiley face or a thumbs-up.\n{{Identical|Thank you}}").replacingOccurrences(of: "$1", with: "😀") : NSLocalizedString("welcome-volunteer-send-usage-reports", value:"Send usage reports", comment:"Text for switch allowing user to choose whether to send usage reports")
        toggleLabel.text = title
        toggle.accessibilityLabel = NSLocalizedString("welcome-volunteer-send-usage-reports", value:"Send usage reports", comment:"Text for switch allowing user to choose whether to send usage reports")
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
