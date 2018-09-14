
import UIKit

//TODO:
// do final trim via trimmingCharacters(in: .whitespaces) on save to remove leading and trailing
// add "Try to keep descriptions short so users can understand the article's subject at a glance"


class DescriptionEditViewController: WMFScrollViewController, Themeable, UITextViewDelegate {
    @objc var article: WMFArticle? = nil

    private lazy var whiteSpaceNormalizationRegex: NSRegularExpression? = {
        guard let regex = try? NSRegularExpression(pattern: "\\s+", options: []) else {
            assertionFailure("Unexpected failure to create regex")
            return nil
        }
        return regex
    }()

    
    
override func didReceiveMemoryWarning() {
    guard view.superview != nil else {
        return
    }
    dismiss(animated: true, completion: nil)
}
    

    public func textViewDidChange(_ textView: UITextView) {
        guard let username = descriptionTextView.text else{
            enableProgressiveButton(false)
            return
        }
        if let text = descriptionTextView.text, let whiteSpaceNormalizationRegex = whiteSpaceNormalizationRegex {
            descriptionTextView.text = whiteSpaceNormalizationRegex.stringByReplacingMatches(in: text, options: [], range: NSMakeRange(0, text.count), withTemplate: " ")
        }
        enableProgressiveButton(username.count > 0)
    }

    @IBOutlet private var learnMoreButton: UIButton!
    @IBOutlet private var subTitleLabel: UILabel!
    @IBOutlet private var descriptionTextView: UITextView! //ThemeableTextField!
    @IBOutlet private var orLabel: UILabel!
    @IBOutlet private var divider: UIView!

    @IBOutlet private var resetPasswordButton: WMFAuthButton!

    private var theme = Theme.standard
/*
    let tokenFetcher = WMFAuthTokenFetcher()
    let passwordResetter = WMFPasswordResetter()
*/
    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named:"close"), style: .plain, target:self, action:#selector(closeButtonPushed(_:)))
        navigationItem.leftBarButtonItem?.accessibilityLabel = CommonStrings.closeButtonAccessibilityLabel

//      usernameField.placeholder = WMFLocalizedString("field-username-placeholder", value:"enter username", comment:"Placeholder text shown inside username field until user taps on it")
        resetPasswordButton.setTitle(WMFLocalizedString("description-edit-publish", value:"Publish description", comment:"Title for publish description button"), for: .normal)
        orLabel.text = WMFLocalizedString("forgot-password-username-or-email-title", value:"Or", comment:"Title shown between the username and email text fields. User only has to specify either username \"Or\" email address\n{{Identical|Or}}")
        
        learnMoreButton.setTitle(WMFLocalizedString("description-edit-learn-more", value:"Learn more", comment:"Title text for description editing learn more button"), for: .normal)
        title = WMFLocalizedString("description-edit-title", value:"Edit description", comment:"Title text for description editing screen")

        view.wmf_configureSubviewsForDynamicType()
        apply(theme: theme)
    }
    
    private var titleDescriptionFor: NSAttributedString {
        let formatString = WMFLocalizedString("description-edit-for-article", value: "Title description for %1$@", comment: "String describing which article title description is being edited. %1$@ is replaced with the article title")
        return String.localizedStringWithFormat(formatString, article?.displayTitleHTML ?? "").byAttributingHTML(with: .subheadline, matching: traitCollection)
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        subTitleLabel.attributedText = titleDescriptionFor
    }
    
    @IBAction func showAboutWikidataPage() {
        wmf_openExternalUrl(URL(string: "https://m.wikidata.org/wiki/Wikidata:Introduction"))
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        enableProgressiveButton(false)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        descriptionTextView.becomeFirstResponder()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        enableProgressiveButton(false)
    }

    func enableProgressiveButton(_ highlight: Bool) {
        resetPasswordButton.isEnabled = highlight
    }

    @IBAction private func resetPasswordButtonTapped(withSender sender: UIButton) {
        save()
    }

    private func save() {
        wmf_hideKeyboard()
//        sendPasswordResetEmail(userName: usernameField.text, email: emailField.text)
    }
    
    @objc func closeButtonPushed(_ : UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
    /*
    func sendPasswordResetEmail(userName: String?, email: String?) {
        guard let siteURL = MWKLanguageLinkController.sharedInstance().appLanguage?.siteURL() else {
            WMFAlertManager.sharedInstance.showAlert("No site url", sticky: true, dismissPreviousAlerts: true, tapCallBack: nil)
            return
        }
        
        let failure: WMFErrorHandler = {error in
            WMFAlertManager.sharedInstance.showErrorAlert(error as NSError, sticky: true, dismissPreviousAlerts: true, tapCallBack: nil)
        }
        
        tokenFetcher.fetchToken(ofType: .csrf, siteURL: siteURL, success: { tokenBlock in
            self.passwordResetter.resetPassword(
                siteURL: siteURL,
                token: tokenBlock.token,
                userName: userName,
                email: email,
                success: { result in
                    self.dismiss(animated: true, completion:nil)
                    WMFAlertManager.sharedInstance.showSuccessAlert(WMFLocalizedString("forgot-password-email-sent", value:"An email with password reset instructions was sent", comment:"Alert text shown when password reset email is sent"), sticky: true, dismissPreviousAlerts: true, tapCallBack: nil)
            }, failure:failure)
        }, failure:failure)
    }
    */
    func apply(theme: Theme) {
        self.theme = theme
        guard viewIfLoaded != nil else {
            return
        }
        
        view.backgroundColor = theme.colors.paperBackground
        view.tintColor = theme.colors.link
        
        let labels = [subTitleLabel, orLabel]
        for label in labels {
            label?.textColor = theme.colors.secondaryText
        }
        
        descriptionTextView.textColor = theme.colors.secondaryText
        divider.backgroundColor = theme.colors.border

        resetPasswordButton.apply(theme: theme)
    }
}
