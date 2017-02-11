
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
    
    @IBOutlet fileprivate var loginContainerView: UIView!
    fileprivate var doneButton: UIBarButtonItem!
    
    public var funnel: LoginFunnel?

    func didTapClose(_ tap: UITapGestureRecognizer) {
        self.dismiss(animated: true, completion: nil)
    }

    func doneButtonPushed(_ tap: UITapGestureRecognizer) {
        save()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named:"close"), style: .plain, target:self, action:#selector(self.didTapClose(_:)))

        doneButton = UIBarButtonItem(title: localizedStringForKeyFallingBackOnEnglish("main-menu-account-login"), style: .plain, target: self, action: #selector(self.doneButtonPushed(_:)))
        
        navigationItem.rightBarButtonItem = doneButton
        
        createAccountButton.textColor = UIColor.wmf_blueTint()
        forgotPasswordButton.textColor = UIColor.wmf_blueTint()

        createAccountButton.text = localizedStringForKeyFallingBackOnEnglish("login-account-creation")
        createAccountButton.isUserInteractionEnabled = true
        
        createAccountButton.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.createAccountButtonPushed(_:))))

        forgotPasswordButton.text = localizedStringForKeyFallingBackOnEnglish("login-forgot-password")

        forgotPasswordButton.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.forgotPasswordButtonPushed(_:))))

        usernameField.placeholder = localizedStringForKeyFallingBackOnEnglish("login-username-placeholder-text")
        passwordField.placeholder = localizedStringForKeyFallingBackOnEnglish("login-password-placeholder-text")

        scrollView.keyboardDismissMode = .interactive

        titleLabel.text = localizedStringForKeyFallingBackOnEnglish("navbar-title-mode-login")

        usernameField.addTarget(self, action: #selector(self.textFieldDidChange(_:)), for: .editingChanged)
        passwordField.addTarget(self, action: #selector(self.textFieldDidChange(_:)), for: .editingChanged)

        usernameUnderlineHeight.constant = 1.0 / UIScreen.main.scale
        passwordUnderlineHeight.constant = 1.0 / UIScreen.main.scale
    }
    
    func textFieldDidChange(_ sender: UITextField) {
        enableProgressiveButton((usernameField.text!.characters.count > 0 && passwordField.text!.characters.count > 0))
    }

    func enableProgressiveButton(_ highlight: Bool) {
        doneButton.isEnabled = highlight
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
        if (textField == self.usernameField) {
            passwordField.becomeFirstResponder()
        } else if (textField == passwordField) {
            save()
        }
        return true
    }

    fileprivate func save() {
        enableProgressiveButton(false)
        WMFAlertManager.sharedInstance.dismissAlert()
        WMFAuthenticationManager.sharedInstance().login(username: usernameField.text!, password: passwordField.text!, retypePassword:nil, oathToken:nil, success: { _ in
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
                    default: break
                }
            }
            
            self.enableProgressiveButton(true)
            WMFAlertManager.sharedInstance.showErrorAlert(error as NSError, sticky: true, dismissPreviousAlerts: true, tapCallBack: nil)
            self.funnel?.logError(error.localizedDescription)
        })
    }

    func showChangeTempPasswordViewController() {
        guard let presenter = self.presentingViewController else {
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
        guard let presenter = self.presentingViewController else {
            return
        }
        dismiss(animated: true, completion: {
            let twoFactorViewController = WMFTwoFactorPasswordViewController.wmf_initialViewControllerFromClassStoryboard()
            twoFactorViewController?.userName = self.usernameField!.text
            twoFactorViewController?.password = self.passwordField!.text
            let navigationController = UINavigationController.init(rootViewController: twoFactorViewController!)
            presenter.present(navigationController, animated: true, completion: nil)
        })
    }

    func forgotPasswordButtonPushed(_ recognizer: UITapGestureRecognizer) {
        guard
            recognizer.state == .ended,
            let presenter = self.presentingViewController else {
                return
        }
        dismiss(animated: true, completion: {
            let forgotPasswordVC = WMFForgotPasswordViewController.wmf_initialViewControllerFromClassStoryboard()
            let navigationController = UINavigationController.init(rootViewController: forgotPasswordVC!)
            presenter.present(navigationController, animated: true, completion: nil)
        })
    }
    
    func createAccountButtonPushed(_ recognizer: UITapGestureRecognizer) {
        guard
            recognizer.state == .ended,
            let presenter = self.presentingViewController else {
                return
        }
        self.funnel?.logCreateAccountAttempt()
        dismiss(animated: true, completion: {
            let createAcctVC = WMFAccountCreationViewController.wmf_initialViewControllerFromClassStoryboard()
            createAcctVC?.funnel = CreateAccountFunnel()
            createAcctVC?.funnel?.logStart(fromLogin: self.funnel?.loginSessionToken)
            let navigationController = UINavigationController.init(rootViewController: createAcctVC!)
            presenter.present(navigationController, animated: true, completion: nil)
        })
    }
}
