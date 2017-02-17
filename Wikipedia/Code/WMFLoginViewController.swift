
import UIKit

class WMFLoginViewController: UIViewController {
    @IBOutlet fileprivate var scrollView: UIScrollView!
    @IBOutlet fileprivate var usernameField: UITextField!
    @IBOutlet fileprivate var passwordField: UITextField!
    @IBOutlet fileprivate var createAccountButton: UILabel!
    @IBOutlet fileprivate var forgotPasswordButton: UILabel!
    @IBOutlet fileprivate var usernameUnderlineHeight: NSLayoutConstraint!
    @IBOutlet fileprivate var passwordUnderlineHeight: NSLayoutConstraint!
    @IBOutlet fileprivate var titleLabel: UILabel!
    @IBOutlet fileprivate var captchaTitleLabel: UILabel!
    @IBOutlet fileprivate var captchaContainer: UIView!
    @IBOutlet fileprivate var spaceBeneathCaptchaContainer: NSLayoutConstraint!

    @IBOutlet fileprivate var loginContainerView: UIView!
    fileprivate var doneButton: UIBarButtonItem!
    
    public var funnel: LoginFunnel?
    fileprivate var captchaViewController: WMFCaptchaViewController?

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
        createAccountButton.isUserInteractionEnabled = true
        
        createAccountButton.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(createAccountButtonPushed(_:))))

        forgotPasswordButton.text = localizedStringForKeyFallingBackOnEnglish("login-forgot-password")

        forgotPasswordButton.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(forgotPasswordButtonPushed(_:))))

        usernameField.placeholder = localizedStringForKeyFallingBackOnEnglish("login-username-placeholder-text")
        passwordField.placeholder = localizedStringForKeyFallingBackOnEnglish("login-password-placeholder-text")

        scrollView.keyboardDismissMode = .interactive

        titleLabel.text = localizedStringForKeyFallingBackOnEnglish("navbar-title-mode-login")
        captchaTitleLabel.text = localizedStringForKeyFallingBackOnEnglish("account-creation-captcha-title")

        usernameField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        passwordField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)

        usernameUnderlineHeight.constant = 1.0 / UIScreen.main.scale
        passwordUnderlineHeight.constant = 1.0 / UIScreen.main.scale
    
        view.wmf_configureSubviewsForDynamicType()
    }
    
    func textFieldDidChange(_ sender: UITextField) {
        enableProgressiveButtonIfNecessary()
    }
    
    fileprivate func enableProgressiveButtonIfNecessary() {
        navigationItem.rightBarButtonItem?.isEnabled = shouldProgressiveButtonBeEnabled()
    }
    
    fileprivate func disableProgressiveButton() {
        navigationItem.rightBarButtonItem?.isEnabled = false
    }
    
    fileprivate func shouldProgressiveButtonBeEnabled() -> Bool {
        return areRequiredFieldsPopulated()
/*
        var shouldEnable = areRequiredFieldsPopulated()
        if showCaptchaContainer && shouldEnable {
            shouldEnable = hasUserEnteredCaptchaText()
        }
        return shouldEnable
*/
    }
    
    fileprivate func requiredInputFields() -> [UITextField] {
        assert(isViewLoaded, "This method is only intended to be called when view is loaded, since they'll all be nil otherwise")
        return [usernameField, passwordField]
    }

    fileprivate func areRequiredFieldsPopulated() -> Bool {
        let firstRequiredFieldWithNoText = requiredInputFields().first(where:{ $0.text?.characters.count == 0 })
        return firstRequiredFieldWithNoText == nil
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        enableProgressiveButtonIfNecessary()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        usernameField.becomeFirstResponder()
    }

    public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if (textField == usernameField) {
            passwordField.becomeFirstResponder()
        } else if (textField == passwordField) {
            save()
        }
        return true
    }

    fileprivate func save() {
        wmf_hideKeyboard()
        disableProgressiveButton()
        WMFAlertManager.sharedInstance.dismissAlert()
        WMFAuthenticationManager.sharedInstance.login(username: usernameField.text!, password: passwordField.text!, retypePassword:nil, oathToken:nil, success: { _ in
            let loggedInMessage = localizedStringForKeyFallingBackOnEnglish("main-menu-account-title-logged-in").replacingOccurrences(of: "$1", with: self.usernameField.text!)
            WMFAlertManager.sharedInstance.showSuccessAlert(loggedInMessage, sticky: false, dismissPreviousAlerts: true, tapCallBack: nil)
            self.dismiss(animated: true, completion: nil)
            self.funnel?.logSuccess()
        }, failure: { error in

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
}
