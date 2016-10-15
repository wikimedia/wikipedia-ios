
class WMFWelcomeUsageReportViewController: UIViewController {

    @IBOutlet var toggleLabel:UILabel!
    @IBOutlet var toggle:UISwitch!
    
    override func viewDidLoad() {
        super.viewDidLoad()
                
        updateToggleLabelTitleForUsageReportsIsOn(false)

        //Set state of the toggle. Also make sure crash manager setting is in sync with this setting - likely to happen on first launch or for previous users.
        if (NSUserDefaults.wmf_userDefaults().wmf_sendUsageReports()) {
            toggle.on = true
            BITHockeyManager.sharedHockeyManager().crashManager.crashManagerStatus = .AutoSend
        } else {
            toggle.on = false
            BITHockeyManager.sharedHockeyManager().crashManager.crashManagerStatus = .AlwaysAsk
        }
    }
    
    func updateToggleLabelTitleForUsageReportsIsOn(isOn: Bool) {
        let title = isOn ? localizedStringForKeyFallingBackOnEnglish("welcome-volunteer-thanks").stringByReplacingOccurrencesOfString("$1", withString: "😀") : localizedStringForKeyFallingBackOnEnglish("welcome-volunteer-send-usage-reports")
        toggleLabel.text = title
    }
    
    @IBAction func toggleAnalytics(withSender sender: UISwitch){
        if(sender.on){
            BITHockeyManager.sharedHockeyManager().crashManager.crashManagerStatus = .AutoSend
            NSUserDefaults.wmf_userDefaults().wmf_setSendUsageReports(true)

        }else{
            BITHockeyManager.sharedHockeyManager().crashManager.crashManagerStatus = .AlwaysAsk
            NSUserDefaults.wmf_userDefaults().wmf_setSendUsageReports(false)
        
        }
        updateToggleLabelTitleForUsageReportsIsOn(sender.on)
    }
}
