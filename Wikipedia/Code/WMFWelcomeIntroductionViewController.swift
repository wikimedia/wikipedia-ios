
class WMFWelcomeIntroductionViewController: UIViewController {

    @IBOutlet fileprivate var descriptionLabel:UILabel!
    @IBOutlet fileprivate var linkLabel:UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
        
        descriptionLabel.text = WMFLocalizedString("welcome-intro-free-encyclopedia-description", value:"Wikipedia is written collaboratively by volunteers and consists of more than 40 million articles in nearly 300 languages.", comment:"Description for introductory welcome screen")

        linkLabel.text = WMFLocalizedString("welcome-intro-free-encyclopedia-more", value:"Learn more about Wikipedia", comment:"Text for link for learning more about Wikipedia on introductory welcome screen")
        
        linkLabel.textColor = .wmf_blue
        
        view.wmf_configureSubviewsForDynamicType()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        linkLabel.font = UIFont.wmf_preferredFontForFontFamily(.systemBold, withTextStyle: .footnote, compatibleWithTraitCollection: traitCollection)
    }

    // TODO: get updated string and hook up the alert when linkLabel tapped
    @IBAction fileprivate func showHowThisWorksAlert(withSender sender: AnyObject) {
        let alert = UIAlertController(
            title:WMFLocalizedString("welcome-notifications-tell-me-more-title", value:"More about notifications", comment:"Title for detailed notification explanation"),
            message:"\(WMFLocalizedString("welcome-notifications-tell-me-more-storage", value:"Notification preferences are stored on device and not based on personal information or activity.", comment:"An explanation of how notifications are stored"))\n\n\(WMFLocalizedString("welcome-notifications-tell-me-more-creation", value:"Notifications are created and delivered on your device by the app, not from our (or third party) servers.", comment:"An explanation of how notifications are created"))",
            preferredStyle:.alert)
        alert.addAction(UIAlertAction(title:WMFLocalizedString("welcome-explore-tell-me-more-done-button", value:"Got it", comment:"Text for button dismissing detailed explanation of new features"), style:.cancel, handler:nil))
        present(alert, animated:true, completion:nil)
    }
}
