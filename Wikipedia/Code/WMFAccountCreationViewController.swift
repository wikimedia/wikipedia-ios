import UIKit
import WMFComponents
import CocoaLumberjackSwift
import HCaptcha
import WMFData

class WMFAccountCreationViewController: WMFScrollViewController, WMFCaptchaViewControllerDelegate, UITextFieldDelegate, UIScrollViewDelegate, Themeable, WMFNavigationBarConfiguring {
    @IBOutlet fileprivate var usernameField: ThemeableTextField!
    @IBOutlet fileprivate var passwordRepeatField: ThemeableTextField!
    @IBOutlet fileprivate var emailField: ThemeableTextField!
    @IBOutlet fileprivate var passwordField: ThemeableTextField!
    
    @IBOutlet fileprivate var usernameAlertLabel: UILabel!

    @IBOutlet fileprivate var usernameTitleLabel: UILabel!
    @IBOutlet fileprivate var passwordTitleLabel: UILabel!
    @IBOutlet fileprivate var passwordRepeatTitleLabel: UILabel!
    @IBOutlet fileprivate var passwordRepeatAlertLabel: UILabel!
    @IBOutlet fileprivate var emailTitleLabel: UILabel!
    @IBOutlet var hcaptchaFinePrintTextView: UITextView!
    @IBOutlet fileprivate var captchaContainer: UIView!
    @IBOutlet fileprivate var loginButton: WMFAuthLinkLabel!
    @IBOutlet fileprivate var titleLabel: UILabel!
    @IBOutlet fileprivate var stackView: UIStackView!
    @IBOutlet fileprivate var createAccountButton: WMFAuthButton!
    @IBOutlet weak var scrollContainerTopConstraint: NSLayoutConstraint!
    
    @IBOutlet fileprivate weak var scrollContainer: UIView!
    
    public var createAccountSuccessCustomDismissBlock: (() -> Void)?
    private var toastView: UIView?
    
    // SINGLETONTODO
    let dataStore = MWKDataStore.shared()
    
    let accountCreationInfoFetcher = WMFAuthAccountCreationInfoFetcher()
    let accountCreator = WMFAccountCreator()
    
    var category: EventCategoryMEP?
    fileprivate var theme = Theme.standard
    
    private var startDate: Date? // to calculate time elapsed between account creation start and account creation success
    
    fileprivate lazy var captchaViewController: WMFCaptchaViewController? = WMFCaptchaViewController.wmf_initialViewControllerFromClassStoryboard()
    
    private var checkingUsernameAvailability: Bool = false
    
    private var hCaptchaToken: String?
    private var hCaptchaFinePrintText: String?
    
    @objc func closeButtonPushed(_ : UIBarButtonItem?) {
        dismiss(animated: true, completion: nil)
    }

    @IBAction fileprivate func createAccountButtonTapped(withSender sender: UIButton) {
        save()
    }
    
    @objc func loginButtonPushed(_ recognizer: UITapGestureRecognizer) {
        guard
            recognizer.state == .ended,
            let presenter = presentingViewController,
            let loginVC = WMFLoginViewController.wmf_initialViewControllerFromClassStoryboard()
        else {
                assertionFailure("Expected view controller(s) not found")
                return
        }
        dismiss(animated: true, completion: {
            loginVC.apply(theme: self.theme)
            presenter.present(WMFComponentNavigationController(rootViewController: loginVC, modalPresentationStyle: .overFullScreen), animated: true, completion: nil)
        })
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        startDate = Date()
    }

    override func accessibilityPerformEscape() -> Bool {
        closeButtonPushed(nil)
        return true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        createAccountButton.setTitle(WMFLocalizedString("account-creation-create-account", value:"Create your account", comment:"Text for create account button"), for: .normal)
        
        scrollView.delegate = self
        
        usernameField.placeholder = WMFLocalizedString("field-username-placeholder", value:"enter username", comment:"Placeholder text shown inside username field until user taps on it")
        passwordField.placeholder = WMFLocalizedString("field-password-placeholder", value:"enter password", comment:"Placeholder text shown inside password field until user taps on it")
        passwordRepeatField.placeholder = WMFLocalizedString("field-password-confirm-placeholder", value:"re-enter password", comment:"Placeholder text shown inside confirm password field until user taps on it")
        emailField.placeholder = WMFLocalizedString("field-email-placeholder", value:"example@example.org", comment:"Placeholder text shown inside email address field until user taps on it")
        usernameTitleLabel.text = WMFLocalizedString("field-username-title", value:"Username", comment:"Title for username field {{Identical|Username}}")
        passwordTitleLabel.text = WMFLocalizedString("field-password-title", value:"Password", comment:"Title for password field {{Identical|Password}}")
        passwordRepeatTitleLabel.text = WMFLocalizedString("field-password-confirm-title", value:"Confirm password", comment:"Title for confirm password field")
        emailTitleLabel.text = WMFLocalizedString("field-email-title-optional", value:"Email (optional)", comment:"Noun. Title for optional email address field.")
        
        stackView.setCustomSpacing(20, after: createAccountButton)
        passwordRepeatAlertLabel.text = WMFLocalizedString("field-alert-password-confirm-mismatch", value:"Passwords do not match", comment:"Alert shown if password confirmation did not match password")

        loginButton.strings = WMFAuthLinkLabelStrings(dollarSignString: WMFLocalizedString("account-creation-have-account", value:"Already have an account? %1$@", comment:"Text for button which shows login interface. %1$@ is the message {{msg-wikimedia|account-creation-log-in}}"), substitutionString: WMFLocalizedString("account-creation-log-in", value:"Log in.", comment:"Log in text to be used as part of a log in button {{Identical|Log in}}"))
        
        loginButton.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(loginButtonPushed(_:))))
        titleLabel.text = WMFLocalizedString("account-creation-title", value:"Create a new account", comment:"Title for account creation interface")
       
        view.wmf_configureSubviewsForDynamicType()
        
        captchaViewController?.captchaDelegate = self
        wmf_add(childController:captchaViewController, andConstrainToEdgesOfContainerView: captchaContainer)
        
        apply(theme: theme)
        
        let authManager = dataStore.authenticationManager
        
        if authManager.authStateIsTemporary {
            let viewModel = WMFTempAccountsToastViewModel(
                    didTapReadMore: {
                        guard let navigationController = self.navigationController else { return }
                        let tempAccountSheetCoordinator = TempAccountSheetCoordinator(navigationController: navigationController, theme: self.theme, dataStore: self.dataStore, didTapDone: { [weak self] in
                            self?.dismiss(animated: true)
                        }, didTapContinue: { [weak self] in
                            self?.dismiss(animated: true)
                        }, isTempAccount: true)
                        _ = tempAccountSheetCoordinator.start()
                    },
                    title: CommonStrings.tempAccountsToastTitle(),
                    readMoreButtonTitle: CommonStrings.tempAccountsReadMoreTitle
                )

            let toastController = WMFTempAccountsToastHostingController(viewModel: viewModel)
            self.toastView = toastController.view

            addChild(toastController)
            view.addSubview(toastController.view)
            toastController.didMove(toParent: self)
            toastController.view.translatesAutoresizingMaskIntoConstraints = false

            NSLayoutConstraint.activate([
               toastController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 0),
               toastController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 0),
               toastController.view.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor)
            ])
        }
    }
    
    private func setupHCaptchaFinePrintText() {
        guard let hCaptchaFinePrintText,
              !hCaptchaFinePrintText.isEmpty else {
            return
        }
        hcaptchaFinePrintTextView.delegate = self
        hcaptchaFinePrintTextView.isEditable = false
        hcaptchaFinePrintTextView.isSelectable = true
        hcaptchaFinePrintTextView.backgroundColor = .clear

        let font = WMFFont.for(.caption1)
        let boldFont = WMFFont.for(.semiboldCaption1)
        let color = theme.colors.secondaryText
        let linkColor = theme.colors.link
        let styles = HtmlUtils.Styles(font: font, boldFont: boldFont, italicsFont: font, boldItalicsFont: font, linkFont: boldFont, color: color, linkColor: linkColor, lineSpacing: 1)
        if let attributedText = try? HtmlUtils.nsAttributedStringFromHtml(hCaptchaFinePrintText, styles: styles) {
            hcaptchaFinePrintTextView.attributedText = attributedText
        } else {
            hcaptchaFinePrintTextView.text = hCaptchaFinePrintText
        }
    }
    
    override func viewDidLayoutSubviews() {
         super.viewDidLayoutSubviews()
        scrollContainerTopConstraint.constant = toastView?.frame.height ?? 0
     }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Check if any captcha is required right away. Things could be configured so captcha is required at all times.
        getCaptcha { [weak self] captcha in
            
            guard let self else { return }
            
            if captcha?.classicInfo != nil {
                self.captchaViewController?.captcha = captcha
                self.hcaptchaFinePrintTextView.isHidden = true
                self.updateEmailFieldReturnKeyType()
                self.enableProgressiveButtonIfNecessary()
            } else if (captcha?.hCaptchaInfo?.needsHCaptcha) ?? false {
                self.fetchAndSetupHCaptchaFinePrint()
            }
        }
        
        updateEmailFieldReturnKeyType()
        enableProgressiveButtonIfNecessary()
        configureNavigationBar()
    }
    
    private func fetchAndSetupHCaptchaFinePrint() {
        let appLanguage = dataStore.languageLinkController.appLanguage
        Task { [weak self] in
            
            guard let self else { return }
            
            let languageCode = appLanguage?.languageCode ?? "en"
            let languageVariantCode = appLanguage?.languageVariantCode
            let project = WMFProject.wikipedia(WMFLanguage(languageCode: languageCode, languageVariantCode: languageVariantCode))
            do {
                let finePrintText = try await MessagesDataController().fetchMessages(keys: ["hcaptcha-privacy-policy"], parseLinks: true, project: project).first?.content

                Task { @MainActor [weak self] in
                    guard let self else { return }
                    self.hCaptchaFinePrintText = finePrintText
                    self.setupHCaptchaFinePrintText()
                    self.hcaptchaFinePrintTextView.isHidden = false
                }
            } catch {
                self.hcaptchaFinePrintTextView.isHidden = true
            }
            
            self.updateEmailFieldReturnKeyType()
            self.enableProgressiveButtonIfNecessary()
        }
        
        
    }
    
    private func configureNavigationBar() {
        let titleConfig = WMFNavigationBarTitleConfig(title: "", customView: nil, alignment: .hidden)
        let closeConfig = WMFNavigationBarCloseButtonConfig(text: CommonStrings.cancelActionTitle, target: self, action: #selector(closeButtonPushed(_:)), alignment: .leading)
        configureNavigationBar(titleConfig: titleConfig, closeButtonConfig: closeConfig, profileButtonConfig: nil, tabsButtonConfig: nil, searchBarConfig: nil, hideNavigationBarOnScroll: false)
    }
    
    fileprivate func getCaptcha(completion: @escaping (WMFCaptcha?) -> Void) {
        let failure: WMFErrorHandler = {error in }
        let siteURL = dataStore.primarySiteURL
        accountCreationInfoFetcher.fetchAccountCreationInfoForSiteURL(siteURL!, success: { info in
            DispatchQueue.main.async {
                completion(info.captcha)
            }
        }, failure:failure)
        enableProgressiveButtonIfNecessary()
    }
    
    private func displayHCaptcha() {
        let hcaptchaVC = WMFHCaptchaViewController()
        hcaptchaVC.theme = theme
        hcaptchaVC.modalTransitionStyle = .crossDissolve
        hcaptchaVC.modalPresentationStyle = .overFullScreen
        
        hcaptchaVC.successAction = { token in
            hcaptchaVC.dismiss(animated: true) { [weak self] in
                self?.hCaptchaToken = token
                self?.createAccount()
            }
        }
        
        hcaptchaVC.errorAction = { error in
            hcaptchaVC.dismiss(animated: true) { [weak self] in
                self?.hCaptchaToken = nil
                WMFAlertManager.sharedInstance.showErrorAlert(error, sticky: true, dismissPreviousAlerts: true)
            }
        }
        
        present(hcaptchaVC, animated: true) {
            hcaptchaVC.validate()
        }
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
        return !(text.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).isEmpty)
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
            } else {
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
        return (dataStore.primarySiteURL)!
    }
    
    public func captchaHideSubtitle() -> Bool {
        return false
    }

    fileprivate func login() {
        WMFAlertManager.sharedInstance.showAlert(WMFLocalizedString("account-creation-logging-in", value:"Logging in...", comment:"Alert shown after account successfully created and the user is being logged in automatically. {{Identical|Logging in}}"), sticky: true, canBeDismissedByUser: false, dismissPreviousAlerts: true, tapCallBack: nil)
        let username = usernameField.text ?? ""
        let password = passwordField.text ?? ""
        dataStore.authenticationManager.login(username: username, password: password, retypePassword: nil, oathToken: nil, emailAuthCode: nil, captchaID: nil, captchaWord: nil) { (loginResult) in
            switch loginResult {
            case .success:
                let loggedInMessage = String.localizedStringWithFormat(WMFLocalizedString("main-menu-account-title-logged-in", value:"Logged in as %1$@", comment:"Header text used when account is logged in. %1$@ will be replaced with current username."), self.usernameField.text ?? "")
                WMFAlertManager.sharedInstance.showSuccessAlert(loggedInMessage, sticky: false, dismissPreviousAlerts: true, tapCallBack: nil)
                if let start = self.startDate {
                    LoginFunnel.shared.logCreateAccountSuccess(category: self.category, timeElapsed: fabs(start.timeIntervalSinceNow))
                } else {
                    assertionFailure("startDate is nil; startDate is required to calculate timeElapsed")
                }
                
                if let customDismissBlock = self.createAccountSuccessCustomDismissBlock {
                    customDismissBlock()
                } else {
                    let presenter = self.presentingViewController
                    self.dismiss(animated: true, completion: {
                        presenter?.wmf_showEnableReadingListSyncPanel(theme: self.theme, oncePerLogin: true)
                    })
                }
                
            case .failure(let error):
                self.setViewControllerUserInteraction(enabled: true)
                self.enableProgressiveButtonIfNecessary()
                WMFAlertManager.sharedInstance.showErrorAlert(error as NSError, sticky: true, dismissPreviousAlerts: true, tapCallBack: nil)
            }
        }
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
        
        usernameAlertLabel.alpha = 0
        usernameField.textColor = theme.colors.primaryText
        passwordRepeatAlertLabel.isHidden = true
        
        guard areRequiredFieldsPopulated() else {
            WMFAlertManager.sharedInstance.showErrorAlertWithMessage(WMFLocalizedString("account-creation-missing-fields", value:"You must enter a username, password, and password confirmation to create an account.", comment:"Error shown when one of the required fields for account creation (username, password, and password confirmation) is empty."), sticky: true, dismissPreviousAlerts: true, tapCallBack: nil)
            return
        }

        guard passwordFieldsMatch() else {
            self.passwordRepeatField.textColor = theme.colors.warning
            self.passwordRepeatField.keyboardAppearance = theme.keyboardAppearance
            self.passwordRepeatAlertLabel.isHidden = false
            self.scrollView.scrollSubview(toTop: self.passwordTitleLabel, offset: 6, animated: true)
            WMFAlertManager.sharedInstance.showErrorAlertWithMessage(WMFLocalizedString("account-creation-passwords-mismatched", value:"Password fields do not match.", comment:"Alert shown if the user doesn't enter the same password in both password boxes"), sticky: false, dismissPreviousAlerts: true, tapCallBack: nil)
            return
        }
        wmf_hideKeyboard()
        
        createAccount()
    }
    
    @IBAction func textFieldDidBeginEditing(_ textField: UITextField) {
        switch textField {
        case usernameField:
            usernameAlertLabel.alpha = 0
            usernameField.textColor = theme.colors.primaryText
            usernameField.keyboardAppearance = theme.keyboardAppearance
        case passwordRepeatField:
            passwordRepeatAlertLabel.isHidden = true
            passwordRepeatField.textColor = theme.colors.primaryText
            passwordRepeatField.keyboardAppearance = theme.keyboardAppearance
        default: break
        }
    }
    
    @IBAction func textFieldDidEndEditing(_ textField: UITextField, reason: UITextField.DidEndEditingReason) {
        guard textField === usernameField, reason == .committed, let username = textField.text else { return }
        let siteURL = dataStore.primarySiteURL!
        
        guard !checkingUsernameAvailability else {
            // Already checking username availability. Returning early to prevent duplicate calls.
            return
        }
        
        checkingUsernameAvailability = true
        
        accountCreator.checkUsername(username, siteURL: siteURL, success: { [weak self] canCreate in
            DispatchQueue.main.async {
                guard let self else {
                    return
                }
                self.checkingUsernameAvailability = false
                if !canCreate {
                    self.usernameAlertLabel.text = WMFAccountCreatorError.usernameUnavailable.localizedDescription
                    self.usernameAlertLabel.alpha = 1
                    self.usernameField.textColor = self.theme.colors.error
                }
            }
        }, failure: { [weak self] error in
            self?.checkingUsernameAvailability = false
        })
    }

    fileprivate func createAccount() {
        
        WMFAlertManager.sharedInstance.showAlert(WMFLocalizedString("account-creation-saving", value:"Saving...", comment:"Alert shown when user saves account creation form. {{Identical|Saving}}"), sticky: true, canBeDismissedByUser: false, dismissPreviousAlerts: true, tapCallBack: nil)
        
        let siteURL = dataStore.primarySiteURL
        
        let creationFailure: WMFErrorHandler = {error in
            DispatchQueue.main.async {
                
                self.hCaptchaToken = nil
                
                self.setViewControllerUserInteraction(enabled: true)
                
                var isCaptchaError = false
                if let error = error as? WMFAccountCreatorError {
                    switch error {
                    case .usernameUnavailable:
                        self.usernameAlertLabel.text = error.localizedDescription
                        self.usernameAlertLabel.alpha = 1
                        self.usernameField.textColor = self.theme.colors.error
                        self.usernameField.keyboardAppearance = self.theme.keyboardAppearance
                        WMFAlertManager.sharedInstance.dismissAlert()
                        return
                    case .wrongCaptcha:
                        isCaptchaError = true
                        
                        self.getCaptcha { [weak self] captcha in
                            
                            guard let self else { return }
                            if captcha?.classicInfo != nil {
                                WMFAlertManager.sharedInstance.showErrorAlert(error as NSError, sticky: true, dismissPreviousAlerts: true, tapCallBack: nil)
                                self.captchaViewController?.captcha = captcha
                                self.captchaViewController?.captchaTextFieldBecomeFirstResponder()
                                self.updateEmailFieldReturnKeyType()
                            } else if let hCaptcha = captcha?.hCaptchaInfo,
                               hCaptcha.needsHCaptcha {
                                self.displayHCaptcha()
                            }
                        }
                        break
                    case .blockedError(let parsedMessage):
                        
                        guard let linkBaseURL = siteURL else {
                            break
                        }
                        
                        WMFAlertManager.sharedInstance.dismissAlert()
                        
                        self.wmf_showBlockedPanel(messageHtml: parsedMessage, linkBaseURL: linkBaseURL, currentTitle: "Special:CreateAccount", theme: self.theme)

                    default:
                        break
                    }
                }
                
                self.enableProgressiveButtonIfNecessary()
                
                if !isCaptchaError {
                    WMFAlertManager.sharedInstance.showErrorAlert(error as NSError, sticky: true, dismissPreviousAlerts: true, tapCallBack: nil)
                }
                
            }
        }
        
        self.setViewControllerUserInteraction(enabled: false)
        accountCreator.createAccount(username: usernameField.text!, password: passwordField.text!, retypePassword: passwordRepeatField.text!, email: emailField.text!, classicCaptchaID: captchaViewController?.captcha?.classicInfo?.captchaID, classicCaptchaWord: captchaViewController?.solution, hCaptchaToken: hCaptchaToken, siteURL: siteURL!, success: {_ in
            DispatchQueue.main.async {
                self.login()
            }
        }, failure: creationFailure)
    }
    
    func apply(theme: Theme) {
        self.theme = theme
        guard viewIfLoaded != nil else {
            return
        }
        
        titleLabel.textColor = theme.colors.primaryText
        for label in [usernameTitleLabel, passwordTitleLabel, passwordRepeatTitleLabel, emailTitleLabel] {
            label?.textColor = theme.colors.secondaryText
        }
        usernameAlertLabel.textColor = theme.colors.error
        passwordRepeatAlertLabel.textColor = theme.colors.warning
        for field in [usernameField, passwordRepeatField, emailField, passwordField] {
            field?.apply(theme: theme)
        }
        scrollContainer.backgroundColor = theme.colors.paperBackground
        view.backgroundColor = theme.colors.paperBackground
        view.tintColor = theme.colors.link
        loginButton.apply(theme: theme)
        createAccountButton.apply(theme: theme)
        captchaContainer.backgroundColor = theme.colors.paperBackground
        captchaViewController?.apply(theme: theme)
        setupHCaptchaFinePrintText()
    }
}

extension WMFAccountCreationViewController: UITextViewDelegate {
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange) -> Bool {
        let config = SinglePageWebViewController.StandardConfig(url: URL, useSimpleNavigationBar: true)
        let inAppWebView = SinglePageWebViewController(configType: .standard(config), theme: theme)
        let navVC = WMFComponentNavigationController(rootViewController: inAppWebView, modalPresentationStyle: .pageSheet)
        present(navVC, animated: true)
        return false
    }
}
