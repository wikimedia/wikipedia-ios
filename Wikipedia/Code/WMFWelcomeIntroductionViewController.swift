
class WMFWelcomeIntroductionViewController: UIViewController {
    
    @IBOutlet private var titleLabel:UILabel!
    @IBOutlet private var subTitleLabel:UILabel!
    @IBOutlet private var tellMeMoreButton:UIButton!
    @IBOutlet private var nextButton:UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.clearColor()
        titleLabel.adjustsFontSizeToFitWidth = true
        titleLabel.text = localizedStringForKeyFallingBackOnEnglish("welcome-explore-new-ways-title").uppercaseStringWithLocale(NSLocale.currentLocale())
        subTitleLabel.text = localizedStringForKeyFallingBackOnEnglish("welcome-explore-new-ways-sub-title")
        tellMeMoreButton.setTitle(localizedStringForKeyFallingBackOnEnglish("welcome-explore-tell-me-more"), forState: .Normal)
        nextButton.setTitle(localizedStringForKeyFallingBackOnEnglish("welcome-explore-continue-button").uppercaseStringWithLocale(NSLocale.currentLocale()), forState: .Normal)
    }
    
    @IBAction private func showHowThisWorksAlert(withSender sender: AnyObject) {
        let alert = UIAlertController(
            title:localizedStringForKeyFallingBackOnEnglish("welcome-notifications-tell-me-more-title"),
            message:"\(localizedStringForKeyFallingBackOnEnglish("welcome-notifications-tell-me-more-storage"))\n\n\(localizedStringForKeyFallingBackOnEnglish("welcome-notifications-tell-me-more-creation"))",
            preferredStyle:.Alert)
        alert.addAction(UIAlertAction(title:localizedStringForKeyFallingBackOnEnglish("welcome-explore-tell-me-more-done-button"), style:.Cancel, handler:nil))
        presentViewController(alert, animated:true, completion:nil)
    }
}
