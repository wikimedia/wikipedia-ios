import UIKit

class WMFLoginViewController: WMFScrollViewController, UITextFieldDelegate, WMFCaptchaViewControllerDelegate, Themeable {
    // SINGLETONTODO
    let dataStore = MWKDataStore.shared()
    
    @IBOutlet fileprivate var usernameField: ThemeableTextField!
    @IBOutlet fileprivate var passwordField: ThemeableTextField!
    @IBOutlet fileprivate var usernameTitleLabel: UILabel!
    @IBOutlet fileprivate var passwordTitleLabel: UILabel!
    @IBOutlet fileprivate var passwordAlertLabel: UILabel!
    @IBOutlet fileprivate var createAccountButton: WMFAuthLinkLabel!
    @IBOutlet fileprivate var forgotPasswordButton: UILabel!
    @IBOutlet fileprivate var titleLabel: UILabel!
    @IBOutlet fileprivate var captchaContainer: UIView!
    @IBOutlet fileprivate var loginButton: WMFAuthButton!
    @IBOutlet weak var scrollContainer: UIView!
    
    public var loginSuccessCompletion: (() -> Void)?
    public var loginDismissedCompletion: (() -> Void)?
    
    @objc public var funnel: WMFLoginFunnel?

    private var startDate: Date? // to calculate time elapsed between login start and login success
    
    fileprivate var theme: Theme = Theme.standard
    
    fileprivate lazy var captchaViewController: WMFCaptchaViewController? = WMFCaptchaViewController.wmf_initialViewControllerFromClassStoryboard()
    private let loginInfoFetcher = WMFAuthLoginInfoFetcher()
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        startDate = Date()
        
    }

    @objc func closeButtonPushed(_ : UIBarButtonItem?) {
        dismiss(animated: true, completion: nil)
        loginDismissedCompletion?()
    }

    @IBAction fileprivate func loginButtonTapped(withSender sender: UIButton) {
        save()
    }

    override func accessibilityPerformEscape() -> Bool {
        closeButtonPushed(nil)
        return true
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named:"close"), style: .plain, target:self, action:#selector(closeButtonPushed(_:)))
        navigationItem.leftBarButtonItem?.accessibilityLabel = CommonStrings.closeButtonAccessibilityLabel

        loginButton.setTitle(WMFLocalizedString("main-menu-account-login", value:"Log in", comment:"Button text for logging in. {{Identical|Log in}}"), for: .normal)
        
        createAccountButton.strings = WMFAuthLinkLabelStrings(dollarSignString: WMFLocalizedString("login-no-account", value:"Don't have an account? %1$@", comment:"Text for create account button. %1$@ is the message {{msg-wikimedia|login-account-join-wikipedia}}"), substitutionString: WMFLocalizedString("login-join-wikipedia", value:"Join Wikipedia.", comment:"Join Wikipedia text to be used as part of a create account button"))
        
        createAccountButton.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(createAccountButtonPushed(_:))))

        forgotPasswordButton.text = WMFLocalizedString("login-forgot-password", value:"Forgot your password?", comment:"Button text for loading the password reminder interface")

        forgotPasswordButton.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(forgotPasswordButtonPushed(_:))))

        usernameField.placeholder = WMFLocalizedString("field-username-placeholder", value:"enter username", comment:"Placeholder text shown inside username field until user taps on it")
        passwordField.placeholder = WMFLocalizedString("field-password-placeholder", value:"enter password", comment:"Placeholder text shown inside password field until user taps on it")

        titleLabel.text = WMFLocalizedString("login-title", value:"Log in to your account", comment:"Title for log in interface")
        usernameTitleLabel.text = WMFLocalizedString("field-username-title", value:"Username", comment:"Title for username field {{Identical|Username}}")
        passwordTitleLabel.text = WMFLocalizedString("field-password-title", value:"Password", comment:"Title for password field {{Identical|Password}}")
    
        view.wmf_configureSubviewsForDynamicType()
        
        captchaViewController?.captchaDelegate = self
        wmf_add(childController:captchaViewController, andConstrainToEdgesOfContainerView: captchaContainer)
        
        apply(theme: theme)
    }
    
    @IBAction func textFieldDidChange(_ sender: UITextField) {
        enableProgressiveButtonIfNecessary()
    }
    
    fileprivate func enableProgressiveButtonIfNecessary() {
        loginButton.isEnabled = shouldProgressiveButtonBeEnabled()
    }
    
    fileprivate func disableProgressiveButton() {
        loginButton.isEnabled = false
    }
    
    fileprivate func shouldProgressiveButtonBeEnabled() -> Bool {
        var shouldEnable = areRequiredFieldsPopulated()
        if captchaIsVisible() && shouldEnable {
            shouldEnable = hasUserEnteredCaptchaText()
        }
        return shouldEnable
    }
    
    fileprivate func hasUserEnteredCaptchaText() -> Bool {
        guard let text = captchaViewController?.solution else {
            return false
        }
        return !(text.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)).isEmpty
    }
    
    fileprivate func requiredInputFields() -> [UITextField] {
        assert(isViewLoaded, "This method is only intended to be called when view is loaded, since they'll all be nil otherwise")
        return [usernameField, passwordField]
    }

    fileprivate func areRequiredFieldsPopulated() -> Bool {
        return requiredInputFields().wmf_allFieldsFilled()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Check if captcha is required right away. Things could be configured so captcha is required at all times.
        getCaptcha()
        
        updatePasswordFieldReturnKeyType()
        enableProgressiveButtonIfNecessary()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        usernameField.becomeFirstResponder()
    }

    public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        switch textField {
        case usernameField:
            passwordField.becomeFirstResponder()
        case passwordField:
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

    @IBAction func textFieldDidBeginEditing(_ textField: UITextField) {
        if textField == passwordField {
            passwordAlertLabel.isHidden = true
            passwordField.textColor = theme.colors.primaryText
            passwordField.keyboardAppearance = theme.keyboardAppearance
        }
    }

    fileprivate func save() {
        wmf_hideKeyboard()
        passwordAlertLabel.isHidden = true
        setViewControllerUserInteraction(enabled: false)
        disableProgressiveButton()
        WMFAlertManager.sharedInstance.showAlert(WMFLocalizedString("account-creation-logging-in", value:"Logging in...", comment:"Alert shown after account successfully created and the user is being logged in automatically. {{Identical|Logging in}}"), sticky: true, canBeDismissedByUser: false, dismissPreviousAlerts: true, tapCallBack: nil)
        guard let username = usernameField.text, let password = passwordField.text else {
            assertionFailure("One or more of the required parameters are nil")
            return
        }
        dataStore.authenticationManager.login(username: username, password: password, retypePassword: nil, oathToken: nil, captchaID: captchaViewController?.captcha?.captchaID, captchaWord: captchaViewController?.solution) { (loginResult) in
            switch loginResult {
            case .success(_):
                let loggedInMessage = String.localizedStringWithFormat(WMFLocalizedString("main-menu-account-title-logged-in", value:"Logged in as %1$@", comment:"Header text used when account is logged in. %1$@ will be replaced with current username."), self.usernameField.text ?? "")
                WMFAlertManager.sharedInstance.showSuccessAlert(loggedInMessage, sticky: false, dismissPreviousAlerts: true, tapCallBack: nil)
                self.loginSuccessCompletion?()
                self.setViewControllerUserInteraction(enabled: true)
                self.dismiss(animated: true)
                self.funnel?.logSuccess()

                if let start = self.startDate {
                    LoginFunnel.shared.logSuccess(timeElapsed: fabs(start.timeIntervalSinceNow))
                } else {
                    assertionFailure("startDate is nil; startDate is required to calculate timeElapsed")
                }
            case .failure(let error):
                self.setViewControllerUserInteraction(enabled: true)

                // Captcha's appear to be one-time, so always try to get a new one on failure.
                self.getCaptcha()

                if let error = error as? WMFAccountLoginError {
                    switch error {
                    case .temporaryPasswordNeedsChange:
                        self.showChangeTempPasswordViewController()
                        return
                    case .needsOathTokenFor2FA:
                        self.showTwoFactorViewController()
                        return
                    case .statusNotPass:
                        self.passwordField.text = nil
                        self.passwordField.becomeFirstResponder()
                    case .wrongPassword:
                        self.passwordAlertLabel.text = error.localizedDescription
                        self.passwordAlertLabel.isHidden = false
                        self.passwordField.textColor = self.theme.colors.error
                        self.passwordField.keyboardAppearance = self.theme.keyboardAppearance
                        self.funnel?.logError(error.localizedDescription)
                        WMFAlertManager.sharedInstance.dismissAlert()
                        return
                    default: break
                    }
                }

                self.enableProgressiveButtonIfNecessary()
                WMFAlertManager.sharedInstance.showErrorAlert(error as NSError, sticky: true, dismissPreviousAlerts: true, tapCallBack: nil)
                self.funnel?.logError(error.localizedDescription)
            default:
                break
            }
        }
    }

    func showChangeTempPasswordViewController() {
        guard let presenter = presentingViewController else {
            return
        }
        dismiss(animated: true, completion: {
            let changePasswordVC = WMFChangePasswordViewController.wmf_initialViewControllerFromClassStoryboard()
            changePasswordVC?.userName = self.usernameField!.text
            changePasswordVC?.apply(theme: self.theme)
            let navigationController = WMFThemeableNavigationController(rootViewController: changePasswordVC!, theme: self.theme, style: .sheet)
            presenter.present(navigationController, animated: true, completion: nil)
        })
    }

    func showTwoFactorViewController() {
        guard
            let presenter = presentingViewController,
            let twoFactorViewController = WMFTwoFactorPasswordViewController.wmf_initialViewControllerFromClassStoryboard()
        else {
            assertionFailure("Expected view controller(s) not found")
            return
        }
        dismiss(animated: true, completion: {
            twoFactorViewController.userName = self.usernameField!.text
            twoFactorViewController.password = self.passwordField!.text
            twoFactorViewController.captchaID = self.captchaViewController?.captcha?.captchaID
            twoFactorViewController.captchaWord = self.captchaViewController?.solution
            twoFactorViewController.apply(theme: self.theme)
            let navigationController = WMFThemeableNavigationController(rootViewController: twoFactorViewController, theme: self.theme, style: .sheet)
            presenter.present(navigationController, animated: true, completion: nil)
        })
    }

    @objc func forgotPasswordButtonPushed(_ recognizer: UITapGestureRecognizer) {
        guard
            recognizer.state == .ended,
            let presenter = presentingViewController,
            let forgotPasswordVC = WMFForgotPasswordViewController.wmf_initialViewControllerFromClassStoryboard()
        else {
            assertionFailure("Expected view controller(s) not found")
            return
        }
        dismiss(animated: true, completion: {
            let navigationController = WMFThemeableNavigationController(rootViewController: forgotPasswordVC, theme: self.theme, style: .sheet)
            forgotPasswordVC.apply(theme: self.theme)
            presenter.present(navigationController, animated: true, completion: nil)
        })
    }
    
    @objc func createAccountButtonPushed(_ recognizer: UITapGestureRecognizer) {
        guard
            recognizer.state == .ended,
            let presenter = presentingViewController,
            let createAcctVC = WMFAccountCreationViewController.wmf_initialViewControllerFromClassStoryboard()
        else {
            assertionFailure("Expected view controller(s) not found")
            return
        }
        createAcctVC.apply(theme: theme)
        funnel?.logCreateAccountAttempt()
        LoginFunnel.shared.logCreateAccountAttempt()
        dismiss(animated: true, completion: {
            createAcctVC.funnel = CreateAccountFunnel()
            createAcctVC.funnel?.logStart(fromLogin: self.funnel?.loginSessionToken)
            let navigationController = WMFThemeableNavigationController(rootViewController: createAcctVC, theme: self.theme, style: .sheet)
            presenter.present(navigationController, animated: true, completion: nil)
        })
    }
    
    fileprivate func getCaptcha() {
        let captchaFailure: WMFErrorHandler = {error in
            DispatchQueue.main.async {
                WMFAlertManager.sharedInstance.showErrorAlert(error as NSError, sticky: true, dismissPreviousAlerts: true, tapCallBack: nil)
                self.funnel?.logError(error.localizedDescription)
            }
        }
        let siteURL = dataStore.primarySiteURL
        loginInfoFetcher.fetchLoginInfoForSiteURL(siteURL!, success: { info in
            DispatchQueue.main.async {
                self.captchaViewController?.captcha = info.captcha
                self.updatePasswordFieldReturnKeyType()
                self.enableProgressiveButtonIfNecessary()
            }
        }, failure: captchaFailure)
    }

    func captchaReloadPushed(_ sender: AnyObject) {
        enableProgressiveButtonIfNecessary()
    }
    
    func captchaSolutionChanged(_ sender: AnyObject, solutionText: String?) {
        enableProgressiveButtonIfNecessary()
    }
    
    public func captchaSiteURL() -> URL {
        return (dataStore.primarySiteURL)!
    }
    
    func captchaKeyboardReturnKeyTapped() {
        save()
    }

    public func captchaHideSubtitle() -> Bool {
        return true
    }

    fileprivate func captchaIsVisible() -> Bool {
        return captchaViewController?.captcha != nil
    }

    fileprivate func updatePasswordFieldReturnKeyType() {
        passwordField.returnKeyType = captchaIsVisible() ? .next : .done
        // Resign and become first responder so keyboard return key updates right away.
        if passwordField.isFirstResponder {
            passwordField.resignFirstResponder()
            passwordField.becomeFirstResponder()
        }
    }
    
    func apply(theme: Theme) {
        self.theme = theme
        guard viewIfLoaded != nil else {
            return
        }
        
        view.backgroundColor = theme.colors.paperBackground
        view.tintColor = theme.colors.link

        titleLabel.textColor = theme.colors.primaryText
        
        let labels = [usernameTitleLabel, passwordTitleLabel, passwordAlertLabel]
        for label in labels {
            label?.textColor = theme.colors.secondaryText
        }
        
        usernameField.apply(theme: theme)
        passwordField.apply(theme: theme)
        
        titleLabel.textColor = theme.colors.primaryText
        forgotPasswordButton.textColor = theme.colors.link
        captchaContainer.backgroundColor = theme.colors.baseBackground
        createAccountButton.apply(theme: theme)
        loginButton.apply(theme: theme)
        passwordAlertLabel.textColor = theme.colors.error
        scrollContainer.backgroundColor = theme.colors.paperBackground
        captchaViewController?.apply(theme: theme)
    }
}
