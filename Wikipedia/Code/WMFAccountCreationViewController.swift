
import UIKit

class WMFAccountCreationViewController: WMFScrollViewController, WMFCaptchaViewControllerDelegate, UITextFieldDelegate, UIScrollViewDelegate {
    @IBOutlet fileprivate var usernameField: UITextField!
    @IBOutlet fileprivate var usernameAlertLabel: UILabel!
    @IBOutlet fileprivate var passwordField: UITextField!
    @IBOutlet fileprivate var passwordRepeatField: UITextField!
    @IBOutlet fileprivate var emailField: UITextField!
    @IBOutlet fileprivate var usernameTitleLabel: UILabel!
    @IBOutlet fileprivate var passwordTitleLabel: UILabel!
    @IBOutlet fileprivate var passwordRepeatTitleLabel: UILabel!
    @IBOutlet fileprivate var passwordRepeatAlertLabel: UILabel!
    @IBOutlet fileprivate var emailTitleLabel: UILabel!
    @IBOutlet fileprivate var captchaContainer: UIView!
    @IBOutlet fileprivate var loginButton: WMFAuthLinkLabel!
    @IBOutlet fileprivate var titleLabel: UILabel!
    @IBOutlet fileprivate var stackView: UIStackView!
    @IBOutlet fileprivate var createAccountButton: WMFAuthButton!

    let accountCreationInfoFetcher = WMFAuthAccountCreationInfoFetcher()
    let tokenFetcher = WMFAuthTokenFetcher()
    let accountCreator = WMFAccountCreator()
    
    public var funnel: CreateAccountFunnel?
    fileprivate lazy var captchaViewController: WMFCaptchaViewController? = WMFCaptchaViewController.wmf_initialViewControllerFromClassStoryboard()
    
    func closeButtonPushed(_ : UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }

    @IBAction fileprivate func createAccountButtonTapped(withSender sender: UIButton) {
        save()
    }

    func loginButtonPushed(_ recognizer: UITapGestureRecognizer) {
        guard
            recognizer.state == .ended,
            let presenter = presentingViewController,
            let loginVC = WMFLoginViewController.wmf_initialViewControllerFromClassStoryboard()
        else {
                assertionFailure("Expected view controller(s) not found")
                return
        }
        dismiss(animated: true, completion: {
            presenter.present(UINavigationController.init(rootViewController: loginVC), animated: true, completion: nil)
        })
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        [titleLabel, usernameTitleLabel, passwordTitleLabel, passwordRepeatTitleLabel, emailTitleLabel].forEach{$0.textColor = .wmf_authTitle}
        usernameAlertLabel.textColor = .wmf_red
        passwordRepeatAlertLabel.textColor = .wmf_yellow

        navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named:"close"), style: .plain, target:self, action:#selector(closeButtonPushed(_:)))

        createAccountButton.setTitle(localizedStringForKeyFallingBackOnEnglish("account-creation-create-account"), for: .normal)
        
        scrollView.delegate = self
        
        usernameField.placeholder = localizedStringForKeyFallingBackOnEnglish("field-username-placeholder")
        passwordField.placeholder = localizedStringForKeyFallingBackOnEnglish("field-password-placeholder")
        passwordRepeatField.placeholder = localizedStringForKeyFallingBackOnEnglish("field-password-confirm-placeholder")
        emailField.placeholder = localizedStringForKeyFallingBackOnEnglish("field-email-placeholder")
        usernameTitleLabel.text = localizedStringForKeyFallingBackOnEnglish("field-username-title")
        passwordTitleLabel.text = localizedStringForKeyFallingBackOnEnglish("field-password-title")
        passwordRepeatTitleLabel.text = localizedStringForKeyFallingBackOnEnglish("field-password-confirm-title")
        emailTitleLabel.text = localizedStringForKeyFallingBackOnEnglish("field-email-title-optional")
        passwordRepeatAlertLabel.text = localizedStringForKeyFallingBackOnEnglish("field-alert-password-confirm-mismatch")
        
        usernameField.wmf_addThinBottomBorder()
        passwordField.wmf_addThinBottomBorder()
        passwordRepeatField.wmf_addThinBottomBorder()
        emailField.wmf_addThinBottomBorder()

        loginButton.strings = WMFAuthLinkLabelStrings(dollarSignString: localizedStringForKeyFallingBackOnEnglish("account-creation-have-account"), substitutionString: localizedStringForKeyFallingBackOnEnglish("account-creation-log-in"))
        
        loginButton.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(loginButtonPushed(_:))))
        titleLabel.text = localizedStringForKeyFallingBackOnEnglish("account-creation-title")
       
        view.wmf_configureSubviewsForDynamicType()
        
        captchaViewController?.captchaDelegate = self
        wmf_add(childController:captchaViewController, andConstrainToEdgesOfContainerView: captchaContainer)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Check if captcha is required right away. Things could be configured so captcha is required at all times.
        getCaptcha()
        
        updateEmailFieldReturnKeyType()
        enableProgressiveButtonIfNecessary()
    }
    
    fileprivate func getCaptcha() {
        let failure: WMFErrorHandler = {error in }
        let siteURL = MWKLanguageLinkController.sharedInstance().appLanguage?.siteURL()
        accountCreationInfoFetcher.fetchAccountCreationInfoForSiteURL(siteURL!, success: { info in
            self.captchaViewController?.captcha = info.captcha
            if info.captcha != nil {
                self.funnel?.logCaptchaShown()
            }
            self.updateEmailFieldReturnKeyType()
            self.enableProgressiveButtonIfNecessary()
        }, failure:failure)
        enableProgressiveButtonIfNecessary()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        usernameField.becomeFirstResponder()
    }

    @IBAction func textFieldDidChange(_ sender: UITextField) {
        enableProgressiveButtonIfNecessary()
    }

    fileprivate func hasUserEnteredCaptchaText() -> Bool {
        guard let text = captchaViewController?.solution else {
            return false
        }
        return (text.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).characters.count > 0)
    }
    
    public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        switch textField {
        case usernameField:
            passwordField.becomeFirstResponder()
        case passwordField:
            passwordRepeatField.becomeFirstResponder()
        case passwordRepeatField:
            emailField.becomeFirstResponder()
        case emailField:
            if captchaIsVisible() {
                captchaViewController?.captchaTextFieldBecomeFirstResponder()
            }else{
                save()
            }
        default:
            assertionFailure("Unhandled text field")
        }
        return true
    }

    func captchaKeyboardReturnKeyTapped() {
        save()
    }

    fileprivate func enableProgressiveButtonIfNecessary() {
        createAccountButton.isEnabled = shouldProgressiveButtonBeEnabled()
    }

    fileprivate func shouldProgressiveButtonBeEnabled() -> Bool {
        var shouldEnable = areRequiredFieldsPopulated()
        if captchaIsVisible() && shouldEnable {
            shouldEnable = hasUserEnteredCaptchaText()
        }
        return shouldEnable
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        WMFAlertManager.sharedInstance.dismissAlert()
        super.viewWillDisappear(animated)
    }
    
    fileprivate func captchaIsVisible() -> Bool {
        return captchaViewController?.captcha != nil
    }
    
    fileprivate func updateEmailFieldReturnKeyType() {
        emailField.returnKeyType = captchaIsVisible() ? .next : .done
        // Resign and become first responder so keyboard return key updates right away.
        if emailField.isFirstResponder {
            emailField.resignFirstResponder()
            emailField.becomeFirstResponder()
        }
    }
    
    func captchaReloadPushed(_ sender: AnyObject) {
        enableProgressiveButtonIfNecessary()
    }
    
    func captchaSolutionChanged(_ sender: AnyObject, solutionText: String?) {
        enableProgressiveButtonIfNecessary()
    }
    
    public func captchaSiteURL() -> URL {
        return (MWKLanguageLinkController.sharedInstance().appLanguage?.siteURL())!
    }
    
    public func captchaHideSubtitle() -> Bool {
        return false
    }

    fileprivate func login() {
        WMFAlertManager.sharedInstance.showAlert(localizedStringForKeyFallingBackOnEnglish("account-creation-logging-in"), sticky: true, dismissPreviousAlerts: true, tapCallBack: nil)
        WMFAuthenticationManager.sharedInstance.login(
            username: usernameField.text!,
            password: passwordField.text!,
            retypePassword: nil,
            oathToken: nil,
            captchaID: nil,
            captchaWord: nil,
            success: { _ in
                let loggedInMessage = localizedStringForKeyFallingBackOnEnglish("main-menu-account-title-logged-in").replacingOccurrences(of: "$1", with: self.usernameField.text!)
                WMFAlertManager.sharedInstance.showSuccessAlert(loggedInMessage, sticky: false, dismissPreviousAlerts: true, tapCallBack: nil)
                self.dismiss(animated: true, completion: nil)
        }, failure: { error in
            self.enableProgressiveButtonIfNecessary()
            WMFAlertManager.sharedInstance.showErrorAlert(error as NSError, sticky: true, dismissPreviousAlerts: true, tapCallBack: nil)
        })
    }
    
    fileprivate func requiredInputFields() -> [UITextField] {
        assert(isViewLoaded, "This method is only intended to be called when view is loaded, since they'll all be nil otherwise")
        return [usernameField, passwordField, passwordRepeatField]
    }

    fileprivate func passwordFieldsMatch() -> Bool {
        return passwordField.text == passwordRepeatField.text
    }
    
    fileprivate func areRequiredFieldsPopulated() -> Bool {
        return requiredInputFields().wmf_allFieldsFilled()
    }
    
    fileprivate func save() {
        
        usernameAlertLabel.isHidden = true
        passwordRepeatAlertLabel.isHidden = true
        
        guard areRequiredFieldsPopulated() else {
            WMFAlertManager.sharedInstance.showErrorAlertWithMessage(localizedStringForKeyFallingBackOnEnglish("account-creation-missing-fields"), sticky: true, dismissPreviousAlerts: true, tapCallBack: nil)
            return
        }

        guard passwordFieldsMatch() else {
            self.passwordRepeatField.textColor = .wmf_yellow
            self.passwordRepeatAlertLabel.isHidden = false
            self.scrollView.scrollSubView(toTop: self.passwordTitleLabel, offset: 6, animated: true)
            WMFAlertManager.sharedInstance.showErrorAlertWithMessage(localizedStringForKeyFallingBackOnEnglish("account-creation-passwords-mismatched"), sticky: false, dismissPreviousAlerts: true, tapCallBack: nil)
            return
        }
        wmf_hideKeyboard()
        createAccount()
    }
    
    @IBAction func textFieldDidBeginEditing(_ textField: UITextField) {
        switch textField {
        case usernameField:
            usernameAlertLabel.isHidden = true
            usernameField.textColor = .black
        case passwordRepeatField:
            passwordRepeatAlertLabel.isHidden = true
            passwordRepeatField.textColor = .black
        default: break
        }
    }

    fileprivate func createAccount() {
        WMFAlertManager.sharedInstance.showAlert(localizedStringForKeyFallingBackOnEnglish("account-creation-saving"), sticky: true, dismissPreviousAlerts: true, tapCallBack: nil)
        
        let creationFailure: WMFErrorHandler = {error in
            // Captcha's appear to be one-time, so always try to get a new one on failure.
            self.getCaptcha()
            
            if let error = error as? WMFAccountCreatorError {
                switch error {
                case .usernameUnavailable:
                    self.usernameAlertLabel.text = error.localizedDescription
                    self.usernameAlertLabel.isHidden = false
                    self.usernameField.textColor = .wmf_red
                    self.funnel?.logError(error.localizedDescription)
                    WMFAlertManager.sharedInstance.dismissAlert()
                    return
                case .wrongCaptcha:
                    self.captchaViewController?.captchaTextFieldBecomeFirstResponder()
                default: break
                }
            }
            
            self.funnel?.logError(error.localizedDescription)
            self.enableProgressiveButtonIfNecessary()
            WMFAlertManager.sharedInstance.showErrorAlert(error as NSError, sticky: true, dismissPreviousAlerts: true, tapCallBack: nil)
        }
        
        let siteURL = MWKLanguageLinkController.sharedInstance().appLanguage?.siteURL()
            tokenFetcher.fetchToken(ofType: .createAccount, siteURL: siteURL!, success: { token in
                self.accountCreator.createAccount(username: self.usernameField.text!, password: self.passwordField.text!, retypePassword: self.passwordRepeatField.text!, email: self.emailField.text!, captchaID:self.captchaViewController?.captcha?.captchaID, captchaWord: self.captchaViewController?.solution, token: token.token, siteURL: siteURL!, success: {_ in
                    self.login()
                }, failure: creationFailure)
            }, failure: creationFailure)
    }
}
