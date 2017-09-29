
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
        
        linkLabel.addGestureRecognizer(UITapGestureRecognizer.init(target: self, action: #selector(showLearnMoreAlert(_:))))
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        linkLabel.font = UIFont.wmf_preferredFontForFontFamily(.systemBold, withTextStyle: .footnote, compatibleWithTraitCollection: traitCollection)
    }

    @objc func showLearnMoreAlert(_ tap: UITapGestureRecognizer) {
        let alert = UIAlertController(
            title:WMFLocalizedString("welcome-intro-free-encyclopedia-more-about", value:"About Wikipedia", comment:"Title for more information about Wikipedia"),
            message:"\(WMFLocalizedString("welcome-intro-free-encyclopedia-more-description", value:"Wikipedia is a global project to build free encyclopedias in all languages of the world. Virtually anyone with Internet access is free to participate by contributing neutral, cited information.", comment:"An explanation of how works"))",
            preferredStyle:.alert)
        alert.addAction(UIAlertAction(title:WMFLocalizedString("welcome-explore-tell-me-more-done-button", value:"Got it", comment:"Text for button dismissing detailed explanation of new features"), style:.cancel, handler:nil))
        present(alert, animated:true, completion:nil)
    }
}
