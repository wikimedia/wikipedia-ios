
class WMFWelcomeIntroductionViewController: UIViewController {
    
    @IBOutlet fileprivate var titleLabel:UILabel!
    @IBOutlet fileprivate var subTitleLabel:UILabel!
    @IBOutlet fileprivate var nextButton:UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.clear
        updateSubtitleLabel()
        titleLabel.text = WMFLocalizedString("welcome-explore-new-ways-title", value:"New ways to explore", comment:"Title for welcome screens including explanation of new notification features").uppercased(with: Locale.current)
        nextButton.setTitle(WMFLocalizedString("welcome-explore-continue-button", value:"Get started", comment:"Text for button for moving to next welcome screen\n{{Identical|Get started}}").uppercased(with: Locale.current), for: UIControlState())
        self.view.wmf_configureSubviewsForDynamicType()
    }
    
    func updateSubtitleLabel() {
        let placesTitle = CommonStrings.placesTitle
        let onThisDayTitle = CommonStrings.onThisDayTitle
        let subtitleFormat = WMFLocalizedString("welcome-explore-features-sub-title", value:"Use the %1$@ tab to discover landmarks near you or search for around the world\n\nTravel back in time with %2$@ to learn what happened today in history", comment:"Sub-title for exploration welcome screen including explanation of new notification features. %1$@ is replaced with the title for the Places tab and %2$@ is replaced with the title of the On this day explore feed card.")
        let subtitleString = String.localizedStringWithFormat(subtitleFormat, placesTitle, onThisDayTitle)
        let placesRange = (subtitleString as NSString).range(of: placesTitle)
        let onThisDayRange = (subtitleString as NSString).range(of: onThisDayTitle)
        let font = UIFont.wmf_preferredFontForFontFamily(.system, withTextStyle: .subheadline, compatibleWithTraitCollection: traitCollection) ?? UIFont.systemFont(ofSize: 15)
        let boldFont = UIFont.wmf_preferredFontForFontFamily(.systemBlack, withTextStyle: .subheadline, compatibleWithTraitCollection: traitCollection) ?? UIFont.boldSystemFont(ofSize: 15)
        let attributedString = NSMutableAttributedString(string: subtitleString, attributes: [NSFontAttributeName: font])
        if placesRange.location != NSNotFound  {
            attributedString.setAttributes([NSFontAttributeName: boldFont], range: placesRange)
        }
        if onThisDayRange.location != NSNotFound {
            attributedString.setAttributes([NSFontAttributeName: boldFont], range: onThisDayRange)
        }
        subTitleLabel.attributedText = attributedString
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        titleLabel.font = UIFont.wmf_preferredFontForFontFamily(.systemBlack, withTextStyle: .title1, compatibleWithTraitCollection: self.traitCollection)
        updateSubtitleLabel()
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
