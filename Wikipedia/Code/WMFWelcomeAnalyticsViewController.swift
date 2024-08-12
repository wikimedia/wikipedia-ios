import WMFComponents

class WMFWelcomeAnalyticsViewController: ThemeableViewController {

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

        descriptionLabel.text = WMFLocalizedString("welcome-privacy-subtitle", value:"We believe that you should not have to provide personal information to participate in the free knowledge movement. Usage data collected for this app is anonymous.", comment:"Sub-title explaining how data usage is anonymous")

        learnMoreButton.setTitle(WMFLocalizedString("welcome-privacy-terms-button-text", value:"Learn more about our privacy policy and terms of use", comment:"Text for links for learning more about data privacy policy and terms of use"), for: .normal)
        updateFonts()
        view.wmf_configureSubviewsForDynamicType()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        updateFonts()
    }

    private func updateFonts() {
        learnMoreButton.titleLabel?.font = WMFFont.for(.mediumFootnote, compatibleWith: traitCollection)
    }

    @IBAction func showPrivacyAndTermsActionSheet(_ sender: AnyObject) {

        let alertPreferredStyle: UIAlertController.Style = UIDevice.current.userInterfaceIdiom == .pad ? .alert : .actionSheet

        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: alertPreferredStyle)

        let goToPrivacyPolicyAction = UIAlertAction(title: CommonStrings.privacyPolicyTitle, style: .default) { action in
            guard let url = URL.init(string: CommonStrings.privacyPolicyURLString) else {
                assertionFailure("Expected URL")
                return
            }
            self.navigate(to: url, useSafari: true)
        }

        let goToTermsOfUseAction = UIAlertAction(title: CommonStrings.termsOfUseTitle, style: .default) { action in
            guard let url = URL.init(string: CommonStrings.termsOfUseURLString) else {
                assertionFailure("Expected URL")
                return
            }
            self.navigate(to: url, useSafari: true)
        }

        let cancelAction = UIAlertAction(title: CommonStrings.cancelActionTitle, style: .cancel)

        alertController.addAction(goToPrivacyPolicyAction)
        alertController.addAction(goToTermsOfUseAction)
        alertController.addAction(cancelAction)

        present(alertController, animated: true)

    }

}
