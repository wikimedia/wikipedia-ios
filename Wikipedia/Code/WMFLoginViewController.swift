
import UIKit

class WMFLoginViewController: WMFScrollViewController, UITextFieldDelegate, WMFCaptchaViewControllerDelegate {
    @IBOutlet fileprivate var usernameField: UITextField!
    @IBOutlet fileprivate var passwordField: UITextField!
    @IBOutlet fileprivate var createAccountButton: UILabel!
    @IBOutlet fileprivate var forgotPasswordButton: UILabel!
    @IBOutlet fileprivate var usernameUnderlineHeight: NSLayoutConstraint!
    @IBOutlet fileprivate var passwordUnderlineHeight: NSLayoutConstraint!
    @IBOutlet fileprivate var titleLabel: UILabel!
    @IBOutlet fileprivate var captchaTitleLabel: UILabel!
    @IBOutlet fileprivate var captchaContainer: UIView!

    @IBOutlet fileprivate var loginContainerView: UIView!
    fileprivate var doneButton: UIBarButtonItem!
    
    public var funnel: LoginFunnel?

    fileprivate var captchaViewController: WMFCaptchaViewController?
    private let loginInfoFetcher = WMFAuthLoginInfoFetcher()
    let tokenFetcher = WMFAuthTokenFetcher()

    func closeButtonPushed(_ : UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }

    func doneButtonPushed(_ : UIBarButtonItem) {
        save()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named:"close"), style: .plain, target:self, action:#selector(closeButtonPushed(_:)))

        doneButton = UIBarButtonItem(title: localizedStringForKeyFallingBackOnEnglish("main-menu-account-login"), style: .plain, target: self, action: #selector(doneButtonPushed(_:)))
        
        navigationItem.rightBarButtonItem = doneButton
        
        createAccountButton.textColor = UIColor.wmf_blueTint()
        forgotPasswordButton.textColor = UIColor.wmf_blueTint()

        createAccountButton.text = localizedStringForKeyFallingBackOnEnglish("login-account-creation")
        
        createAccountButton.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(createAccountButtonPushed(_:))))

        forgotPasswordButton.text = localizedStringForKeyFallingBackOnEnglish("login-forgot-password")

        forgotPasswordButton.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(forgotPasswordButtonPushed(_:))))

        usernameField.placeholder = localizedStringForKeyFallingBackOnEnglish("login-username-placeholder-text")
        passwordField.placeholder = localizedStringForKeyFallingBackOnEnglish("login-password-placeholder-text")

        titleLabel.text = localizedStringForKeyFallingBackOnEnglish("navbar-title-mode-login")
        captchaTitleLabel.text = localizedStringForKeyFallingBackOnEnglish("account-creation-captcha-title")

        usernameUnderlineHeight.constant = 1.0 / UIScreen.main.scale
        passwordUnderlineHeight.constant = 1.0 / UIScreen.main.scale
    
        view.wmf_configureSubviewsForDynamicType()
        
        setCaptchaAlpha(0)
    }
    
    @IBAction func textFieldDidChange(_ sender: UITextField) {
        enableProgressiveButtonIfNecessary()
    }
    
    fileprivate func enableProgressiveButtonIfNecessary() {
        navigationItem.rightBarButtonItem?.isEnabled = shouldProgressiveButtonBeEnabled()
    }
    
    fileprivate func disableProgressiveButton() {
        navigationItem.rightBarButtonItem?.isEnabled = false
    }
    
    fileprivate func shouldProgressiveButtonBeEnabled() -> Bool {
        var shouldEnable = areRequiredFieldsPopulated()
        if showCaptchaContainer && shouldEnable {
            shouldEnable = hasUserEnteredCaptchaText()
        }
        return shouldEnable
    }
    
    fileprivate func hasUserEnteredCaptchaText() -> Bool {
        guard let text = captchaViewController?.solution else {
            return false
        }
        return (text.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).characters.count > 0)
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
        
        showCaptchaContainer = false

        captchaViewController = WMFCaptchaViewController.wmf_initialViewControllerFromClassStoryboard()
        captchaViewController?.captchaDelegate = self
        
        // Allow contained view height to control container height: http://stackoverflow.com/a/35431534/135557
        captchaViewController?.view.translatesAutoresizingMaskIntoConstraints = false
        
        wmf_addChildController(captchaViewController, andConstrainToEdgesOfContainerView: captchaContainer)
        
        // Check if captcha is required right away. Things could be configured so captcha is required at all times.
        getCaptcha()
        
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
            if showCaptchaContainer {
                captchaViewController?.captchaTextBoxBecomeFirstResponder()
            }else{
                save()
            }
        default:
            assert(false, "Unhandled text field")
        }
        return true
    }

    fileprivate func save() {
        wmf_hideKeyboard()
        disableProgressiveButton()
        WMFAlertManager.sharedInstance.dismissAlert()
        WMFAuthenticationManager.sharedInstance.login(username: usernameField.text!, password: passwordField.text!, retypePassword:nil, oathToken:nil, captchaID: captchaViewController?.captcha?.captchaID, captchaWord: captchaViewController?.solution, success: { _ in
            let loggedInMessage = localizedStringForKeyFallingBackOnEnglish("main-menu-account-title-logged-in").replacingOccurrences(of: "$1", with: self.usernameField.text!)
            WMFAlertManager.sharedInstance.showSuccessAlert(loggedInMessage, sticky: false, dismissPreviousAlerts: true, tapCallBack: nil)
            self.dismiss(animated: true, completion: nil)
            self.funnel?.logSuccess()
        }, failure: { error in

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
                default: break
                }
            }
            
            self.enableProgressiveButtonIfNecessary()
            WMFAlertManager.sharedInstance.showErrorAlert(error as NSError, sticky: true, dismissPreviousAlerts: true, tapCallBack: nil)
            self.funnel?.logError(error.localizedDescription)
        })
    }

    func showChangeTempPasswordViewController() {
        guard let presenter = presentingViewController else {
            return
        }
        dismiss(animated: true, completion: {
            let changePasswordVC = WMFChangePasswordViewController.wmf_initialViewControllerFromClassStoryboard()
            changePasswordVC?.userName = self.usernameField!.text
            let navigationController = UINavigationController.init(rootViewController: changePasswordVC!)
            presenter.present(navigationController, animated: true, completion: nil)
        })
    }

    func showTwoFactorViewController() {
        guard
            let presenter = presentingViewController,
            let twoFactorViewController = WMFTwoFactorPasswordViewController.wmf_initialViewControllerFromClassStoryboard()
        else {
            assert(false, "Expected view controller(s) not found")
            return
        }
        dismiss(animated: true, completion: {
            twoFactorViewController.userName = self.usernameField!.text
            twoFactorViewController.password = self.passwordField!.text
            twoFactorViewController.captchaID = self.captchaViewController?.captcha?.captchaID
            twoFactorViewController.captchaWord = self.captchaViewController?.solution
            let navigationController = UINavigationController.init(rootViewController: twoFactorViewController)
            presenter.present(navigationController, animated: true, completion: nil)
        })
    }

    func forgotPasswordButtonPushed(_ recognizer: UITapGestureRecognizer) {
        guard
            recognizer.state == .ended,
            let presenter = presentingViewController,
            let forgotPasswordVC = WMFForgotPasswordViewController.wmf_initialViewControllerFromClassStoryboard()
        else {
            assert(false, "Expected view controller(s) not found")
            return
        }
        dismiss(animated: true, completion: {
            let navigationController = UINavigationController.init(rootViewController: forgotPasswordVC)
            presenter.present(navigationController, animated: true, completion: nil)
        })
    }
    
    func createAccountButtonPushed(_ recognizer: UITapGestureRecognizer) {
        guard
            recognizer.state == .ended,
            let presenter = presentingViewController,
            let createAcctVC = WMFAccountCreationViewController.wmf_initialViewControllerFromClassStoryboard()
        else {
            assert(false, "Expected view controller(s) not found")
            return
        }
        funnel?.logCreateAccountAttempt()
        dismiss(animated: true, completion: {
            createAcctVC.funnel = CreateAccountFunnel()
            createAcctVC.funnel?.logStart(fromLogin: self.funnel?.loginSessionToken)
            let navigationController = UINavigationController.init(rootViewController: createAcctVC)
            presenter.present(navigationController, animated: true, completion: nil)
        })
    }
    
    fileprivate func getCaptcha() {
        let captchaFailure: WMFErrorHandler = {error in
            WMFAlertManager.sharedInstance.showErrorAlert(error as NSError, sticky: true, dismissPreviousAlerts: true, tapCallBack: nil)
            self.funnel?.logError(error.localizedDescription)
        }
        let siteURL = MWKLanguageLinkController.sharedInstance().appLanguage?.siteURL()
        loginInfoFetcher.fetchLoginInfoForSiteURL(siteURL!, success: { info in
            self.captchaViewController?.captcha = info.captcha
            self.showCaptchaContainer = (info.captcha != nil)
            self.enableProgressiveButtonIfNecessary()
        }, failure: captchaFailure)
    }

    func captchaReloadPushed(_ sender: AnyObject) {
        self.enableProgressiveButtonIfNecessary()
    }
    
    func captchaSolutionChanged(_ sender: AnyObject, solutionText: String?) {
        enableProgressiveButtonIfNecessary()
    }
    
    public func captchaSiteURL() -> URL {
        return (MWKLanguageLinkController.sharedInstance().appLanguage?.siteURL())!
    }
    
    func captchaKeyboardReturnKeyTapped() {
        save()
    }

    fileprivate var showCaptchaContainer: Bool = false {
        didSet {
            UIView.animate(withDuration: 0.4, animations: {
                self.setCaptchaAlpha(self.showCaptchaContainer ? 1 : 0)
            }, completion: { _ in
                self.updatePasswordFieldReturnKeyType()
                self.enableProgressiveButtonIfNecessary()
            })
        }
    }

    fileprivate func updatePasswordFieldReturnKeyType() {
        self.passwordField.returnKeyType = self.showCaptchaContainer ? .next : .done
        // Resign and become first responder so keyboard return key updates right away.
        if self.passwordField.isFirstResponder {
            self.passwordField.resignFirstResponder()
            self.passwordField.becomeFirstResponder()
        }
    }
    
    fileprivate func setCaptchaAlpha(_ alpha: CGFloat) {
        captchaContainer.alpha = alpha
        captchaTitleLabel.alpha = alpha
    }
}
