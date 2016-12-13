
class WMFWelcomeIntroductionViewController: UIViewController {
    
    @IBOutlet fileprivate var titleLabel:UILabel!
    @IBOutlet fileprivate var subTitleLabel:UILabel!
    @IBOutlet fileprivate var tellMeMoreButton:UIButton!
    @IBOutlet fileprivate var nextButton:UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.clear
        titleLabel.text = localizedStringForKeyFallingBackOnEnglish("welcome-explore-new-ways-title").uppercased(with: Locale.current)
        subTitleLabel.text = localizedStringForKeyFallingBackOnEnglish("welcome-explore-new-ways-sub-title")
        tellMeMoreButton.setTitle(localizedStringForKeyFallingBackOnEnglish("welcome-explore-tell-me-more"), for: UIControlState())
        nextButton.setTitle(localizedStringForKeyFallingBackOnEnglish("welcome-explore-continue-button").uppercased(with: Locale.current), for: UIControlState())
        self.view.wmf_configureSubviewsForDynamicType()
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        titleLabel.font = UIFont.wmf_preferredFontForFontFamily(.systemBlack, withTextStyle: UIFontTextStyle.title1, compatibleWithTraitCollection: self.traitCollection)
    }

    @IBAction fileprivate func showHowThisWorksAlert(withSender sender: AnyObject) {
        let alert = UIAlertController(
            title:localizedStringForKeyFallingBackOnEnglish("welcome-notifications-tell-me-more-title"),
            message:"\(localizedStringForKeyFallingBackOnEnglish("welcome-notifications-tell-me-more-storage"))\n\n\(localizedStringForKeyFallingBackOnEnglish("welcome-notifications-tell-me-more-creation"))",
            preferredStyle:.alert)
        alert.addAction(UIAlertAction(title:localizedStringForKeyFallingBackOnEnglish("welcome-explore-tell-me-more-done-button"), style:.cancel, handler:nil))
        present(alert, animated:true, completion:nil)
    }
}
