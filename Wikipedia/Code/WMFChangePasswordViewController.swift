import WMF
import UIKit

class WMFChangePasswordViewController: WMFScrollViewController, Themeable {
    
    @IBOutlet fileprivate var titleLabel: UILabel!
    @IBOutlet fileprivate var subTitleLabel: UILabel!
    @IBOutlet fileprivate var passwordField: ThemeableTextField!
    @IBOutlet fileprivate var retypeField: ThemeableTextField!
    @IBOutlet fileprivate var passwordTitleLabel: UILabel!
    @IBOutlet fileprivate var retypeTitleLabel: UILabel!
    @IBOutlet fileprivate var saveButton: WMFAuthButton!
    
    fileprivate var theme: Theme = Theme.standard

    public var userName:String?
    
    @IBAction fileprivate func saveButtonTapped(withSender sender: UIButton) {
        save()
    }

    @IBAction func textFieldDidChange(_ sender: UITextField) {
        guard
            let password = passwordField.text,
            let retype = retypeField.text
            else {
                enableProgressiveButton(false)
                return
        }
        enableProgressiveButton((!password.isEmpty && !retype.isEmpty))
    }
    
    fileprivate func passwordFieldsMatch() -> Bool {
        return passwordField.text == retypeField.text
    }

    func enableProgressiveButton(_ highlight: Bool) {
        saveButton.isEnabled = highlight
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        enableProgressiveButton(false)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        passwordField.becomeFirstResponder()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        enableProgressiveButton(false)
    }
    
    public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == passwordField {
            retypeField.becomeFirstResponder()
        } else if textField == retypeField {
            save()
        }
        return true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        

        navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named:"close"), style: .plain, target:self, action:#selector(closeButtonPushed(_:)))
        navigationItem.leftBarButtonItem?.accessibilityLabel = CommonStrings.closeButtonAccessibilityLabel

        titleLabel.text = WMFLocalizedString("new-password-title", value:"Set your password", comment:"Title for password change interface")
        subTitleLabel.text = WMFLocalizedString("new-password-instructions", value:"You logged in with a temporary password. To finish logging in set a new password here.", comment:"Instructions for password change interface")
        passwordField.placeholder = WMFLocalizedString("field-new-password-placeholder", value:"enter new password", comment:"Placeholder text shown inside new password field until user taps on it")
        retypeField.placeholder = WMFLocalizedString("field-new-password-confirm-placeholder", value:"re-enter new password", comment:"Placeholder text shown inside confirm new password field until user taps on it")
        passwordTitleLabel.text = WMFLocalizedString("field-new-password-title", value:"New password", comment:"Title for new password field")
        retypeTitleLabel.text = WMFLocalizedString("field-new-password-confirm-title", value:"Confirm new password", comment:"Title for confirm new password field")
        
        view.wmf_configureSubviewsForDynamicType()
        
        apply(theme: theme)
    }
    
    @objc func closeButtonPushed(_ : UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
    
    fileprivate func save() {
        
        guard passwordFieldsMatch() else {
            WMFAlertManager.sharedInstance.showErrorAlertWithMessage(WMFLocalizedString("account-creation-passwords-mismatched", value:"Password fields do not match.", comment:"Alert shown if the user doesn't enter the same password in both password boxes"), sticky: true, dismissPreviousAlerts: true, tapCallBack: nil)
            passwordField.text = nil
            retypeField.text = nil
            passwordField.becomeFirstResponder()
            return
        }
        
        wmf_hideKeyboard()
        enableProgressiveButton(false)
        WMFAlertManager.sharedInstance.dismissAlert()
                
        guard let userName = userName,
            let password = passwordField.text,
            let retypePassword = retypeField.text else {
            assertionFailure("One or more of the required parameters are nil")
            return
        }

        // SINGLETONTODO
        MWKDataStore.shared().authenticationManager.login(username: userName, password: password, retypePassword: retypePassword, oathToken: nil, captchaID: nil, captchaWord: nil) { (loginResult) in
            switch loginResult {
            case .success:
                let loggedInMessage = String.localizedStringWithFormat(WMFLocalizedString("main-menu-account-title-logged-in", value:"Logged in as %1$@", comment:"Header text used when account is logged in. %1$@ will be replaced with current username."), userName)
                WMFAlertManager.sharedInstance.showSuccessAlert(loggedInMessage, sticky: false, dismissPreviousAlerts: true, tapCallBack: nil)
                self.dismiss(animated: true, completion: nil)
            case .failure(let error):
                self.enableProgressiveButton(true)
                WMFAlertManager.sharedInstance.showErrorAlert(error as NSError, sticky: true, dismissPreviousAlerts: true, tapCallBack: nil)
                if let error = error as? URLError {
                    if error.code != .notConnectedToInternet {
                        self.passwordField.text = nil
                        self.retypeField.text = nil
                    }
                }
            }
        }
    }
    
    
    func apply(theme: Theme) {
        self.theme = theme
        guard viewIfLoaded != nil else {
            return
        }
        
        view.backgroundColor = theme.colors.paperBackground
        view.tintColor = theme.colors.link
        
        let labels = [titleLabel, subTitleLabel, passwordTitleLabel, retypeTitleLabel]
        for label in labels {
            label?.textColor = theme.colors.secondaryText
        }
        
        let fields = [passwordField, retypeField]
        for field in fields {
            field?.apply(theme: theme)
        }
        
        saveButton.apply(theme: theme)
    }
}
