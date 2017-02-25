
import UIKit

class WMFAccountCreationViewController: UIViewController, WMFCaptchaViewControllerDelegate, UITextFieldDelegate, UIScrollViewDelegate {
    @IBOutlet var usernameField: UITextField!
    @IBOutlet var passwordField: UITextField!
    @IBOutlet var passwordRepeatField: UITextField!
    @IBOutlet var emailField: UITextField!
    @IBOutlet var captchaContainer: UIView!
    @IBOutlet var scrollView: UIScrollView!
    @IBOutlet var loginButton: UILabel!
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var usernameUnderlineHeight: NSLayoutConstraint!
    @IBOutlet var passwordUnderlineHeight: NSLayoutConstraint!
    @IBOutlet var passwordConfirmUnderlineHeight: NSLayoutConstraint!
    @IBOutlet var emailUnderlineHeight: NSLayoutConstraint!
    @IBOutlet var spaceBeneathCaptchaContainer: NSLayoutConstraint!
    @IBOutlet var createAccountContainerView: UIView!
    @IBOutlet var captchaTitleLabel: UILabel!
    @IBOutlet var captchaSubtitleLabel: UILabel!

    let accountCreationInfoFetcher = WMFAuthAccountCreationInfoFetcher()
    let tokenFetcher = WMFAuthTokenFetcher()
    let accountCreator = WMFAccountCreator()
    
    fileprivate var rightButton: UIBarButtonItem?
    public var funnel: CreateAccountFunnel?
    fileprivate var captchaViewController: WMFCaptchaViewController?

    fileprivate func adjustScrollLimitForCaptchaVisiblity() {
        // Reminder: spaceBeneathCaptchaContainer constraint is space *below* captcha container -
        // that's why below for the show case we don't have to "convertPoint".
        spaceBeneathCaptchaContainer.constant = (showCaptchaContainer)
            ? (view.frame.size.height - (captchaContainer.frame.size.height / 2))
            : (view.frame.size.height - loginButton.convert(CGPoint.zero, to:scrollView).y)
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: { (context) in
            // Ensure adjustScrollLimitForCaptchaVisiblity gets called again after rotating.
            self.view.setNeedsUpdateConstraints()
            if self.showCaptchaContainer {
                self.scrollView.scrollSubView(toTop: self.captchaContainer, animated:false)
            }
        })
    }
    
    func closeButtonPushed(_ : UIBarButtonItem) {
        if (showCaptchaContainer) {
            showCaptchaContainer = false
        } else {
            dismiss(animated: true, completion: nil)
        }
    }

    func nextButtonPushed(_ : UIBarButtonItem) {
        WMFAlertManager.sharedInstance.showAlert(localizedStringForKeyFallingBackOnEnglish("account-creation-saving"), sticky: true, dismissPreviousAlerts: true, tapCallBack: nil)
        save()
    }

    func loginButtonPushed(_ recognizer: UITapGestureRecognizer) {
        guard
            recognizer.state == .ended,
            let presenter = presentingViewController,
            let loginVC = WMFLoginViewController.wmf_initialViewControllerFromClassStoryboard()
        else {
                assert(false, "Expected view controller(s) not found")
                return
        }
        dismiss(animated: true, completion: {
            presenter.present(UINavigationController.init(rootViewController: loginVC), animated: true, completion: nil)
        })
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named:"close"), style: .plain, target:self, action:#selector(closeButtonPushed(_:)))

        rightButton = UIBarButtonItem(title: localizedStringForKeyFallingBackOnEnglish("button-next"), style: .plain, target: self, action: #selector(nextButtonPushed(_:)))
        
        navigationItem.rightBarButtonItem = rightButton
        
        scrollView.delegate = self
        
        setCaptchaAlpha(0)
        
        usernameField.placeholder = localizedStringForKeyFallingBackOnEnglish("account-creation-username-placeholder-text")
        passwordField.placeholder = localizedStringForKeyFallingBackOnEnglish("account-creation-password-placeholder-text")
        passwordRepeatField.placeholder = localizedStringForKeyFallingBackOnEnglish("account-creation-password-confirm-placeholder-text")
        emailField.placeholder = localizedStringForKeyFallingBackOnEnglish("account-creation-email-placeholder-text")

        scrollView.keyboardDismissMode = .interactive
        
        usernameUnderlineHeight.constant = 1.0 / UIScreen.main.scale
        passwordUnderlineHeight.constant = usernameUnderlineHeight.constant;
        passwordConfirmUnderlineHeight.constant = usernameUnderlineHeight.constant;
        emailUnderlineHeight.constant = usernameUnderlineHeight.constant;

        loginButton.textColor = UIColor.wmf_blueTint()
        loginButton.text = localizedStringForKeyFallingBackOnEnglish("account-creation-login")
        loginButton.isUserInteractionEnabled = true
        
        loginButton.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(loginButtonPushed(_:))))
        titleLabel.text = localizedStringForKeyFallingBackOnEnglish("navbar-title-mode-create-account")
       
        captchaTitleLabel.text = localizedStringForKeyFallingBackOnEnglish("account-creation-captcha-title")
        
        // Reminder: used a label instead of a button for subtitle because of multi-line string issues with UIButton.
        captchaSubtitleLabel.attributedText = captchaSubtitleAttributedString
        captchaSubtitleLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(requestAnAccountTapped(_:))))

        view.wmf_configureSubviewsForDynamicType()
    }

    func requestAnAccountTapped(_ recognizer: UITapGestureRecognizer) {
        wmf_openExternalUrl(URL.init(string: "https://en.wikipedia.org/wiki/Wikipedia:Request_an_account"))
    }

    fileprivate var captchaSubtitleAttributedString: NSAttributedString {
        get {
            // Note: uses the font from the storyboard so the attributed string respects the
            // storyboard dynamic type font choice and responds to dynamic type size changes.
            let attributes: [String : Any] = [
                NSFontAttributeName : captchaSubtitleLabel.font
            ]
            let substitutionAttributes: [String : Any] = [
                NSForegroundColorAttributeName : UIColor.wmf_blueTint()
            ]
            let cannotSeeImageText = localizedStringForKeyFallingBackOnEnglish("account-creation-captcha-cannot-see-image")
            let requestAccountText = localizedStringForKeyFallingBackOnEnglish("account-creation-captcha-request-account")
            return cannotSeeImageText.attributedString(attributes: attributes, substitutionStrings: [requestAccountText], substitutionAttributes: [substitutionAttributes])
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        captchaViewController = WMFCaptchaViewController.wmf_initialViewControllerFromClassStoryboard()
        captchaViewController?.captchaDelegate = self
        wmf_addChildController(captchaViewController, andConstrainToEdgesOfContainerView: captchaContainer)
        showCaptchaContainer = false
        
        // Check if captcha is required right away. Things could be configured so captcha is required at all times.
        getCaptcha()
    }
    
    fileprivate func getCaptcha() {
        let failure: WMFErrorHandler = {error in }
        let siteURL = MWKLanguageLinkController.sharedInstance().appLanguage?.siteURL()
        self.accountCreationInfoFetcher.fetchAccountCreationInfoForSiteURL(siteURL!, success: { info in
            self.captchaViewController?.captcha = info.captcha
            self.showCaptchaContainer = (info.captcha != nil)
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
        if (textField == usernameField) {
            passwordField.becomeFirstResponder()
        } else if (textField == passwordField) {
            passwordRepeatField.becomeFirstResponder()
        } else if (textField == passwordRepeatField) {
            emailField.becomeFirstResponder()
        } else {
            assert((textField == emailField), "Received -textFieldShouldReturn for unexpected text field: \(textField)")
            save()
        }
        return true
    }

    fileprivate func enableProgressiveButtonIfNecessary() {
        navigationItem.rightBarButtonItem?.isEnabled = shouldProgressiveButtonBeEnabled()
    }

    fileprivate func shouldProgressiveButtonBeEnabled() -> Bool {
        var shouldEnable = areRequiredFieldsPopulated()
        if showCaptchaContainer && shouldEnable {
            shouldEnable = hasUserEnteredCaptchaText()
        }
        return shouldEnable
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        WMFAlertManager.sharedInstance.dismissAlert()
        super.viewWillDisappear(animated)
    }

    fileprivate func setCaptchaAlpha(_ alpha: CGFloat) {
        captchaContainer.alpha = alpha
        captchaTitleLabel.alpha = alpha
        captchaSubtitleLabel.alpha = alpha
    }
    
    fileprivate var showCaptchaContainer: Bool = false {
        didSet {
            rightButton?.title = showCaptchaContainer ? localizedStringForKeyFallingBackOnEnglish("button-done") : localizedStringForKeyFallingBackOnEnglish("button-next")
            let duration: TimeInterval = 0.5
            view.setNeedsUpdateConstraints()
            
            if showCaptchaContainer {
                funnel?.logCaptchaShown()
                DispatchQueue.main.async(execute: {
                    UIView.animate(withDuration: duration, animations: {
                        self.setCaptchaAlpha(1)
                        self.scrollView.scrollSubView(toTop: self.captchaTitleLabel, offset:20, animated:false)
                    }, completion: { _ in
                        self.enableProgressiveButtonIfNecessary()
                    })
                })
            }else{
                DispatchQueue.main.async(execute: {
                    WMFAlertManager.sharedInstance.dismissAlert()
                    UIView.animate(withDuration: duration, animations: {
                        self.setCaptchaAlpha(0)
                        self.scrollView.setContentOffset(CGPoint.zero, animated: false)
                    }, completion: { _ in
                        self.enableProgressiveButtonIfNecessary()
                    })
                })
            }
        }
    }
    
    func captchaReloadPushed(_ sender: AnyObject) {
    WMFAlertManager.sharedInstance.showAlert(localizedStringForKeyFallingBackOnEnglish("account-creation-captcha-obtaining"), sticky: false, dismissPreviousAlerts: true, tapCallBack: nil)
    }
    
    func captchaSolutionChanged(_ sender: AnyObject, solutionText: String?) {
        enableProgressiveButtonIfNecessary()
    }
    
    public func captchaSiteURL() -> URL {
        return (MWKLanguageLinkController.sharedInstance().appLanguage?.siteURL())!
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
    
    override func updateViewConstraints() {
        adjustScrollLimitForCaptchaVisiblity()
        super.updateViewConstraints()
    }

    fileprivate func save() {
        guard areRequiredFieldsPopulated() else {
            WMFAlertManager.sharedInstance.showErrorAlertWithMessage(localizedStringForKeyFallingBackOnEnglish("account-creation-missing-fields"), sticky: true, dismissPreviousAlerts: true, tapCallBack: nil)
            return
        }

        guard passwordFieldsMatch() else {
            WMFAlertManager.sharedInstance.showErrorAlertWithMessage(localizedStringForKeyFallingBackOnEnglish("account-creation-passwords-mismatched"), sticky: true, dismissPreviousAlerts: true, tapCallBack: nil)
            UIView.animate(withDuration: 0.3, animations: {
                self.scrollView.setContentOffset(CGPoint.zero, animated: false)
            }, completion: { _ in
                self.passwordRepeatField.becomeFirstResponder()
            })
            return
        }
        wmf_hideKeyboard()
        createAccount()
    }
    
    fileprivate func createAccount() {
        let creationFailure: WMFErrorHandler = {error in
            // Captcha's appear to be one-time, so always try to get a new one on failure.
            self.getCaptcha()
            
            self.funnel?.logError(error.localizedDescription)
            self.enableProgressiveButtonIfNecessary()
            WMFAlertManager.sharedInstance.showErrorAlert(error as NSError, sticky: true, dismissPreviousAlerts: true, tapCallBack: nil)
        }
        
        let siteURL = MWKLanguageLinkController.sharedInstance().appLanguage?.siteURL()
            self.tokenFetcher.fetchToken(ofType: .createAccount, siteURL: siteURL!, success: { token in
                self.accountCreator.createAccount(username: self.usernameField.text!, password: self.passwordField.text!, retypePassword: self.passwordRepeatField.text!, email: self.emailField.text!, captchaID:self.captchaViewController?.captcha?.captchaID, captchaWord: self.captchaViewController?.solution, token: token.token, siteURL: siteURL!, success: {_ in
                    self.login()
                }, failure: creationFailure)
            }, failure: creationFailure)
    }
}
