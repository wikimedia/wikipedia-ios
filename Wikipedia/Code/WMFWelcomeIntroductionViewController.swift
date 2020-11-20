
class WMFWelcomeIntroductionViewController: ThemeableViewController {
    override func apply(theme: Theme) {
        super.apply(theme: theme)
        guard viewIfLoaded != nil else {
            return
        }
        learnMoreButton.setTitleColor(theme.colors.link, for: .normal)
    }

    @IBOutlet private var descriptionLabel:UILabel!
    @IBOutlet private var learnMoreButton:UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
        
        descriptionLabel.text = WMFLocalizedString("welcome-intro-free-encyclopedia-description", value:"Wikipedia is written collaboratively by volunteers and consists of more than 40 million articles in over 300 languages.", comment:"Description for introductory welcome screen")

        learnMoreButton.setTitle(WMFLocalizedString("welcome-intro-free-encyclopedia-more", value:"Learn more about Wikipedia", comment:"Text for link for learning more about Wikipedia on introductory welcome screen"), for: .normal)
        
        updateFonts()
        view.wmf_configureSubviewsForDynamicType()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        updateFonts()
    }

    private func updateFonts() {
        learnMoreButton.titleLabel?.font = UIFont.wmf_font(.semiboldFootnote, compatibleWithTraitCollection: traitCollection)
    }

    @IBAction func showLearnMoreAlert(withSender sender: AnyObject) {
        let alert = UIAlertController(
            title:WMFLocalizedString("welcome-intro-free-encyclopedia-more-about", value:"About Wikipedia", comment:"Title for more information about Wikipedia"),
            message:"\(WMFLocalizedString("welcome-intro-free-encyclopedia-more-description", value:"Wikipedia is a global project to build free encyclopedias in all languages of the world. Virtually anyone with Internet access is free to participate by contributing neutral, cited information.", comment:"An explanation of how works"))",
            preferredStyle:.alert)
        alert.addAction(UIAlertAction(title: CommonStrings.gotItButtonTitle, style:.cancel, handler:nil))
        present(alert, animated:true, completion:nil)
    }
}
