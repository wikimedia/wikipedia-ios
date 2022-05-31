import UIKit

class WMFForgotPasswordViewController: WMFScrollViewController, Themeable {

    @IBOutlet fileprivate var titleLabel: UILabel!
    @IBOutlet fileprivate var subTitleLabel: UILabel!
    @IBOutlet fileprivate var usernameField: ThemeableTextField!
    @IBOutlet fileprivate var emailField: ThemeableTextField!
    @IBOutlet fileprivate var usernameTitleLabel: UILabel!
    @IBOutlet fileprivate var emailTitleLabel: UILabel!
    @IBOutlet fileprivate var orLabel: UILabel!

    @IBOutlet fileprivate var resetPasswordButton: WMFAuthButton!

    fileprivate var theme = Theme.standard
    
    let passwordResetter = WMFPasswordResetter()

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named:"close"), style: .plain, target:self, action:#selector(closeButtonPushed(_:)))
        navigationItem.leftBarButtonItem?.accessibilityLabel = CommonStrings.closeButtonAccessibilityLabel

        titleLabel.text = WMFLocalizedString("forgot-password-title", value:"Reset password", comment:"Title for reset password interface {{Identical|Reset password}}")
        subTitleLabel.text = WMFLocalizedString("forgot-password-instructions", value:"Fill in one of the fields below to receive password reset instructions via email", comment:"Instructions for resetting password")
        usernameField.placeholder = WMFLocalizedString("field-username-placeholder", value:"enter username", comment:"Placeholder text shown inside username field until user taps on it")
        emailField.placeholder = WMFLocalizedString("field-email-placeholder", value:"example@example.org", comment:"Placeholder text shown inside email address field until user taps on it")
        usernameTitleLabel.text = WMFLocalizedString("field-username-title", value:"Username", comment:"Title for username field {{Identical|Username}}")
        emailTitleLabel.text = WMFLocalizedString("field-email-title", value:"Email", comment:"Noun. Title for email address field. {{Identical|E-mail}}")
        resetPasswordButton.setTitle(WMFLocalizedString("forgot-password-button-title", value:"Reset", comment:"Title for reset password button {{Identical|Reset}}"), for: .normal)
        orLabel.text = WMFLocalizedString("forgot-password-username-or-email-title", value:"Or", comment:"Title shown between the username and email text fields. User only has to specify either username \"Or\" email address {{Identical|Or}}")
        
        view.wmf_configureSubviewsForDynamicType()
        
        apply(theme: theme)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        enableProgressiveButton(false)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        usernameField.becomeFirstResponder()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        enableProgressiveButton(false)
    }
    
    public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == usernameField {
            emailField.becomeFirstResponder()
        } else if textField == emailField {
            save()
        }
        return true
    }

    @IBAction func textFieldDidChange(_ sender: UITextField) {
        guard
            let username = usernameField.text,
            let email = emailField.text
            else {
                enableProgressiveButton(false)
                return
        }
        enableProgressiveButton((!username.isEmpty || !email.isEmpty))
    }

    func enableProgressiveButton(_ highlight: Bool) {
        resetPasswordButton.isEnabled = highlight
    }

    @IBAction fileprivate func resetPasswordButtonTapped(withSender sender: UIButton) {
        save()
    }

    fileprivate func save() {
        wmf_hideKeyboard()
        sendPasswordResetEmail(userName: usernameField.text, email: emailField.text)
    }
    
    @objc func closeButtonPushed(_ : UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
    
    func sendPasswordResetEmail(userName: String?, email: String?) {
        guard let siteURL = MWKDataStore.shared().primarySiteURL else {
            WMFAlertManager.sharedInstance.showAlert("No site url", sticky: true, dismissPreviousAlerts: true, tapCallBack: nil)
            return
        }
        
        let failure: WMFErrorHandler = { error in
            DispatchQueue.main.async {
                WMFAlertManager.sharedInstance.showErrorAlert(error as NSError, sticky: true, dismissPreviousAlerts: true, tapCallBack: nil)
            }
        }
        
        passwordResetter.resetPassword(
            siteURL: siteURL,
            userName: userName,
            email: email,
            success: { result in
                DispatchQueue.main.async {
                    WMFAlertManager.sharedInstance.showSuccessAlert(WMFLocalizedString("forgot-password-email-sent", value:"An email with password reset instructions was sent", comment:"Alert text shown when password reset email is sent"), sticky: true, dismissPreviousAlerts: true, tapCallBack: nil)
                }
        }, failure: failure)
    }
    
    func apply(theme: Theme) {
        self.theme = theme
        guard viewIfLoaded != nil else {
            return
        }
        
        view.backgroundColor = theme.colors.paperBackground
        view.tintColor = theme.colors.link
        
        titleLabel.textColor = theme.colors.primaryText
        
        let labels = [subTitleLabel, usernameTitleLabel, emailTitleLabel, orLabel]
        for label in labels {
            label?.textColor = theme.colors.secondaryText
        }
        
        usernameField.apply(theme: theme)
        emailField.apply(theme: theme)
        
        resetPasswordButton.apply(theme: theme)
    }
}
