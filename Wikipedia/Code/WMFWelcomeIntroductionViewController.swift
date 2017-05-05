
class WMFWelcomeIntroductionViewController: UIViewController {
    
    @IBOutlet fileprivate var titleLabel:UILabel!
    @IBOutlet fileprivate var subTitleLabel:UILabel!
    @IBOutlet fileprivate var tellMeMoreButton:UIButton!
    @IBOutlet fileprivate var nextButton:UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.clear
        titleLabel.text = WMFLocalizedString("welcome-explore-new-ways-title", value:"New ways to explore", comment:"Title for welcome screens including explanation of new notification features").uppercased(with: Locale.current)
        subTitleLabel.text = WMFLocalizedString("welcome-explore-new-ways-sub-title", value:"New notifications and widgets to help you discover interesting articles", comment:"Sub-title for exploration welcome screen including explanation of new notification features")
        tellMeMoreButton.setTitle(WMFLocalizedString("welcome-explore-tell-me-more", value:"Tell me more", comment:"Title for link which when tapped shows explaination of new exploration features"), for: UIControlState())
        nextButton.setTitle(WMFLocalizedString("welcome-explore-continue-button", value:"Get started", comment:"Text for button for moving to next welcome screen\n{{Identical|Get started}}").uppercased(with: Locale.current), for: UIControlState())
        self.view.wmf_configureSubviewsForDynamicType()
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        titleLabel.font = UIFont.wmf_preferredFontForFontFamily(.systemBlack, withTextStyle: .title1, compatibleWithTraitCollection: self.traitCollection)
    }

    @IBAction fileprivate func showHowThisWorksAlert(withSender sender: AnyObject) {
        let alert = UIAlertController(
            title:WMFLocalizedString("welcome-notifications-tell-me-more-title", value:"More about notifications", comment:"Title for detailed notification explanation"),
            message:"\(WMFLocalizedString("welcome-notifications-tell-me-more-storage", value:"Notification preferences are stored on device and not based on personal information or activity.", comment:"An explanation of how notifications are stored"))\n\n\(WMFLocalizedString("welcome-notifications-tell-me-more-creation", value:"Notifications are created and delivered on your device by the app, not from our (or third party) servers.", comment:"An explanation of how notifications are created"))",
            preferredStyle:.alert)
        alert.addAction(UIAlertAction(title:WMFLocalizedString("welcome-explore-tell-me-more-done-button", value:"Got it", comment:"Text for button dismissing detailed explanation of new features"), style:.cancel, handler:nil))
        present(alert, animated:true, completion:nil)
    }
}
