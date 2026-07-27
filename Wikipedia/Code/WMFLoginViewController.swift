import UIKit
import WMFComponents
import SwiftUI
import WMFData
import CocoaLumberjackSwift
import WMFNativeLocalizations
import WMFTestKitchen

class WMFLoginViewController: WMFScrollViewController, UITextFieldDelegate, WMFCaptchaViewControllerDelegate, Themeable, WMFNavigationBarConfiguring {
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
    @IBOutlet weak var scrollContainerTopConstraint: NSLayoutConstraint!
    @IBOutlet fileprivate var captchaContainer: UIView!
    @IBOutlet var hcaptchaFinePrintTextView: UITextView!
    @IBOutlet fileprivate var loginButton: WMFAuthButton!
    @IBOutlet weak var scrollContainer: UIView!

    public var loginSuccessCompletion: (() -> Void)?
    public var createAccountSuccessCustomDismissBlock: (() -> Void)?
    public var loginDismissedCompletion: (() -> Void)?
    @objc public var loginDismissedHandler: (() -> Void)? {
        get { loginDismissedCompletion }
        set { loginDismissedCompletion = newValue }
    }

    private var startDate: Date? // to calculate time elapsed between login start and login success
    private var toastView: UIView?

    var category: EventCategoryMEP?
    fileprivate var theme: Theme = Theme.standard

    private lazy var authInstrument: InstrumentImpl = {
        TestKitchenAdapter.shared.client.getInstrument(name: "apps-authentication")
            .setDefaultActionSource("login_form")
            .startFunnel(name: "login_account")
    }()
    
    fileprivate lazy var captchaViewController: WMFCaptchaViewController? = WMFCaptchaViewController.wmf_initialViewControllerFromClassStoryboard()
    private let loginInfoFetcher = WMFAuthLoginInfoFetcher()

    private var hCaptchaToken: String?
    private var hCaptchaFinePrintText: String?

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        startDate = Date()

    }

    @objc func closeButtonPushed(_ : UIBarButtonItem?) {
        authInstrument.submitInteraction(action: "click", elementId: "cancel")
        WMFToastManager.sharedInstance.dismissCurrentToast()
        dismiss(animated: true, completion: nil)
        loginDismissedCompletion?()
    }

    @IBAction fileprivate func loginButtonTapped(withSender sender: UIButton) {
        authInstrument.submitInteraction(action: "click", elementId: "login_button")
        save()
    }

    override func accessibilityPerformEscape() -> Bool {
        closeButtonPushed(nil)
        return true
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        loginButton.setTitle(CommonStrings.logIn, for: .normal)

        createAccountButton.strings = WMFAuthLinkLabelStrings(dollarSignString: WMFLocalizedString("login-no-account", value:"Don't have an account? %1$@", comment:"Text for create account button. %1$@ is the message {{msg-wikimedia|login-account-join-wikipedia}}"), substitutionString: WMFLocalizedString("login-join-wikipedia", value:"Join Wikipedia.", comment:"Join Wikipedia text to be used as part of a create account button"))

        createAccountButton.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(createAccountButtonPushed(_:))))

        forgotPasswordButton.text = WMFLocalizedString("login-forgot-password", value:"Forgot your password?", comment:"Button text for loading the password reminder interface")

        forgotPasswordButton.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(forgotPasswordButtonPushed(_:))))

        usernameField.placeholder = WMFLocalizedString("field-username-placeholder", value:"enter username", comment:"Placeholder text shown inside username field until user taps on it")
        passwordField.placeholder = WMFLocalizedString("field-password-placeholder", value:"enter password", comment:"Placeholder text shown inside password field until user taps on it")
        usernameField.textContentType = .username
        passwordField.textContentType = .password

        titleLabel.text = WMFLocalizedString("login-title", value:"Log in to your account", comment:"Title for log in interface")
        usernameTitleLabel.text = WMFLocalizedString("field-username-title", value:"Username", comment:"Title for username field {{Identical|Username}}")
        passwordTitleLabel.text = WMFLocalizedString("field-password-title", value:"Password", comment:"Title for password field {{Identical|Password}}")

        view.wmf_configureSubviewsForDynamicType()

        captchaViewController?.captchaDelegate = self
        wmf_add(childController:captchaViewController, andConstrainToEdgesOfContainerView: captchaContainer)

        apply(theme: theme)

        if WMFTempAccountDataController.shared.primaryWikiHasTempAccountsEnabled {
            let authManager = dataStore.authenticationManager
            if authManager.authStateIsTemporary {
                let viewModel = WMFTempAccountsToastViewModel(
                    didTapReadMore: { [weak self] in
                        
                        guard let self else { return }
                        
                        guard let navigationController = self.navigationController else { return }
                        let tempAccountSheetCoordinator = TempAccountSheetCoordinator(navigationController: navigationController, theme: self.theme, dataStore: self.dataStore, didTapDone: { [weak self] in
                            self?.dismiss(animated: true)
                        }, didTapContinue: {[weak self] in
                            self?.dismiss(animated: true)
                        }, isTempAccount: true)
                        _ = tempAccountSheetCoordinator.start()
                    },
                    title: CommonStrings.tempAccountsToastTitle(),
                    readMoreButtonTitle: CommonStrings.tempAccountsReadMoreTitle
                )

                let toastController = WMFTempAccountsToastHostingController(viewModel: viewModel)
                toastView = toastController.view

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
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        scrollContainerTopConstraint.constant = toastView?.frame.height ?? 0
    }

    private func configureNavigationBar() {
        let titleConfig = WMFNavigationBarTitleConfig(title: "", customView: nil, alignment: .hidden)
        let closeConfig = WMFLargeCloseButtonConfig(imageType: .plainX, target: self, action: #selector(closeButtonPushed(_:)), alignment: .leading)
        configureNavigationBar(titleConfig: titleConfig, closeButtonConfig: closeConfig, profileButtonConfig: nil, tabsButtonConfig: nil, searchBarConfig: nil, hideNavigationBarOnScroll: false)
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

        configureNavigationBar()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        let actionContext = category.map { ["invoke_source": $0.rawValue] }
        authInstrument.submitInteraction(action: "impression", actionContext: actionContext)
        usernameField.becomeFirstResponder()
    }

    public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        switch textField {
        case usernameField:
            passwordField.becomeFirstResponder()
        case passwordField:
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

    @IBAction func textFieldDidBeginEditing(_ textField: UITextField) {
        if textField == passwordField {
            passwordAlertLabel.isHidden = true
            passwordField.textColor = theme.colors.primaryText
            passwordField.keyboardAppearance = theme.keyboardAppearance
            
            authInstrument.submitInteraction(action: "type", elementId: "password")
        } else if textField == usernameField {
            authInstrument.submitInteraction(action: "type", elementId: "username")
        }
    }

    fileprivate func save() {
        wmf_hideKeyboard()
        passwordAlertLabel.isHidden = true
        setViewControllerUserInteraction(enabled: false)
        disableProgressiveButton()
        WMFToastManager.sharedInstance.showToast(WMFLocalizedString("account-creation-logging-in", value:"Logging in...", comment:"Alert shown after account successfully created and the user is being logged in automatically. {{Identical|Logging in}}"), sticky: true, dismissPreviousToasts: true, tapCallBack: nil)
        guard let username = usernameField.text, let password = passwordField.text else {
            assertionFailure("One or more of the required parameters are nil")
            return
        }

        dataStore.authenticationManager.login(username: username, password: password, retypePassword: nil, oathToken: nil, emailAuthCode: nil, captchaID: captchaViewController?.captcha?.classicInfo?.captchaID, captchaWord: captchaViewController?.solution, hCaptchaToken: hCaptchaToken) { [weak self] (loginResult) in

            guard let self else { return }

            switch loginResult {
            case .success:
                let loggedInMessage = String.localizedStringWithFormat(WMFLocalizedString("main-menu-account-title-logged-in", value:"Logged in as %1$@", comment:"Header text used when account is logged in. %1$@ will be replaced with current username."), self.usernameField.text ?? "")
                self.loginSuccessCompletion?()
                self.setViewControllerUserInteraction(enabled: true)
                
                var actionContext: [String: String]? = nil
                if let category {
                    actionContext = ["invoke_source": category.rawValue]
                }
                self.authInstrument.submitInteraction(action: "success", actionContext: actionContext)

                if let start = self.startDate {
                    LoginFunnel.shared.logSuccess(category: self.category, timeElapsed: fabs(start.timeIntervalSinceNow))
                } else {
                    assertionFailure("startDate is nil; startDate is required to calculate timeElapsed")
                }

                // Dismiss the "Logging in..." toast before dismissing the VC, then show
                // the success toast after the modal is fully gone so it appears on the correct VC.
                WMFToastManager.sharedInstance.dismissCurrentToast()
                self.dismiss(animated: true) {
                    WMFToastManager.sharedInstance.showToast(loggedInMessage, sticky: false, dismissPreviousToasts: true, tapCallBack: nil)
                }
            case .failure(let error):
                self.setViewControllerUserInteraction(enabled: true)

                // hCaptcha tokens are single-use, so discard the previous one on any failure.
                self.hCaptchaToken = nil

                // Captcha's appear to be one-time, so always try to get a new one on failure.
                self.getCaptcha()

                if let error = error as? WMFAccountLoginError {

                    defer {
                        self.authInstrument.submitInteraction(action: "error", actionContext: ["validation_error": error.testKitchenValidationError])
                    }

                    switch error {
                    case .temporaryPasswordNeedsChange:
                        self.showChangeTempPasswordViewController()
                        return
                    case .needsOathTokenFor2FA:
                        self.showTwoFactorViewController(isEmailAuth: false)
                        return
                    case .needsEmailAuthToken:
                        self.showTwoFactorViewController(isEmailAuth: true)
                        return
                    case .hCaptchaRequired(let siteKey, _):
                        WMFToastManager.sharedInstance.dismissCurrentToast()
                        self.displayHCaptcha(siteKey: siteKey)
                        return
                    case .statusNotPass:
                        self.passwordField.text = nil
                    case .wrongPassword:
                        self.passwordAlertLabel.text = error.localizedDescription
                        self.passwordAlertLabel.isHidden = false
                        self.passwordField.textColor = self.theme.colors.error
                        self.passwordField.keyboardAppearance = self.theme.keyboardAppearance
                        WMFToastManager.sharedInstance.dismissCurrentToast()
                        return
                    default: break
                    }
                } else {
                    self.authInstrument.submitInteraction(action: "error", actionContext: ["code": error.logDescription])
                }

                self.enableProgressiveButtonIfNecessary()
                WMFToastManager.sharedInstance.showErrorAlert(error as NSError, sticky: true, dismissPreviousToasts: true, tapCallBack: nil)
            }
        }
    }

    func showChangeTempPasswordViewController() {
        guard let presenter = presentingViewController else {
            return
        }
        dismiss(animated: true, completion: { [weak self] in
            
            guard let self else { return }
            
            guard let changePasswordVC = WMFChangePasswordViewController.wmf_initialViewControllerFromClassStoryboard() else {
                return
            }

            changePasswordVC.userName = self.usernameField!.text
            changePasswordVC.apply(theme: self.theme)
            let navigationController = WMFComponentNavigationController(rootViewController: changePasswordVC, modalPresentationStyle: .overFullScreen)
            presenter.present(navigationController, animated: true, completion: nil)
        })
    }

    func showTwoFactorViewController(isEmailAuth: Bool) {
        guard
            let presenter = presentingViewController,
            let twoFactorViewController = WMFTwoFactorPasswordViewController.wmf_initialViewControllerFromClassStoryboard()
        else {
            assertionFailure("Expected view controller(s) not found")
            return
        }
        
        twoFactorViewController.authInstrument = authInstrument
        twoFactorViewController.loginSuccessCompletion = loginSuccessCompletion
        twoFactorViewController.category = category
        
        if isEmailAuth {
            twoFactorViewController.setDisplayModeToShortAlphanumeric()
        }

        dismiss(animated: true, completion: { [weak self] in
            
            guard let self else { return }
            
            twoFactorViewController.userName = self.usernameField!.text
            twoFactorViewController.password = self.passwordField!.text
            twoFactorViewController.captchaID = self.captchaViewController?.captcha?.classicInfo?.captchaID
            twoFactorViewController.captchaWord = self.captchaViewController?.solution
            twoFactorViewController.apply(theme: self.theme)
            let navigationController = WMFComponentNavigationController(rootViewController: twoFactorViewController, modalPresentationStyle: .overFullScreen)
            presenter.present(navigationController, animated: true, completion: nil)
        })
    }

    @objc func forgotPasswordButtonPushed(_ recognizer: UITapGestureRecognizer) {
        authInstrument.submitInteraction(action: "click", elementId: "password_forgot")
        guard
            recognizer.state == .ended,
            let presenter = presentingViewController,
            let forgotPasswordVC = WMFForgotPasswordViewController.wmf_initialViewControllerFromClassStoryboard()
        else {
            assertionFailure("Expected view controller(s) not found")
            return
        }
        dismiss(animated: true, completion: { [weak self] in
            
            guard let self else { return }
            
            let navigationController = WMFComponentNavigationController(rootViewController: forgotPasswordVC, modalPresentationStyle: .overFullScreen)
            forgotPasswordVC.apply(theme: self.theme)
            presenter.present(navigationController, animated: true, completion: nil)
        })
    }

    @objc func createAccountButtonPushed(_ recognizer: UITapGestureRecognizer) {
        authInstrument.submitInteraction(action: "click", elementId: "create_account")
        guard
            recognizer.state == .ended,
            let presenter = presentingViewController,
            let createAcctVC = WMFAccountCreationViewController.wmf_initialViewControllerFromClassStoryboard()
        else {
            assertionFailure("Expected view controller(s) not found")
            return
        }
        createAcctVC.category = category
        createAcctVC.createAccountSuccessCustomDismissBlock = createAccountSuccessCustomDismissBlock
        createAcctVC.apply(theme: theme)
        LoginFunnel.shared.logCreateAccountAttempt(category: category)
        dismiss(animated: true, completion: { [weak self] in
            
            guard let self else { return }
            
            let navigationController = WMFComponentNavigationController(rootViewController: createAcctVC, modalPresentationStyle: .overFullScreen)
            createAcctVC.category = self.category
            presenter.present(navigationController, animated: true, completion: nil)
        })
    }

    fileprivate func getCaptcha() {
        let captchaFailure: WMFErrorHandler = {error in
            DispatchQueue.main.async {
                WMFToastManager.sharedInstance.showErrorAlert(error as NSError, sticky: true, dismissPreviousToasts: true, tapCallBack: nil)
            }
        }
        let siteURL = dataStore.primarySiteURL
        loginInfoFetcher.fetchLoginInfoForSiteURL(siteURL!, success: { info in
            DispatchQueue.main.async { [weak self] in

                guard let self else { return }

                if info.captcha?.classicInfo != nil {
                    self.captchaViewController?.captcha = info.captcha
                    self.hcaptchaFinePrintTextView.isHidden = true
                } else if (info.captcha?.hCaptchaInfo?.needsHCaptcha) ?? false {
                    // hCaptcha challenge is presented on demand from the login failure handler; here we only surface the required fine print.
                    self.captchaViewController?.captcha = nil
                    self.fetchAndSetupHCaptchaFinePrint()
                } else {
                    self.captchaViewController?.captcha = nil
                    self.hcaptchaFinePrintTextView.isHidden = true
                }
                self.updatePasswordFieldReturnKeyType()
                self.enableProgressiveButtonIfNecessary()
            }
        }, failure: captchaFailure)
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

    private func fetchAndSetupHCaptchaFinePrint() {
        let appLanguage = dataStore.languageLinkController.appLanguage
        Task { @MainActor [weak self] in

            guard let self else { return }

            let languageCode = appLanguage?.languageCode ?? "en"
            let languageVariantCode = appLanguage?.languageVariantCode
            let project = WMFProject.wikipedia(WMFLanguage(languageCode: languageCode, languageVariantCode: languageVariantCode))
            do {
                let finePrintText = try await MessagesDataController().fetchMessages(keys: ["hcaptcha-privacy-policy"], parseLinks: true, project: project).first?.content

                self.hCaptchaFinePrintText = finePrintText
                self.setupHCaptchaFinePrintText()
                self.hcaptchaFinePrintTextView.isHidden = finePrintText?.isEmpty != false
            } catch {
                self.hcaptchaFinePrintTextView.isHidden = true
            }

            self.enableProgressiveButtonIfNecessary()
        }
    }

    private func displayHCaptcha(siteKey: String?) {
        let hcaptchaVC = WMFHCaptchaViewController()
        hcaptchaVC.authInstrument = authInstrument
        hcaptchaVC.siteKey = siteKey
        hcaptchaVC.theme = theme
        hcaptchaVC.modalTransitionStyle = .crossDissolve
        hcaptchaVC.modalPresentationStyle = .overFullScreen

        hcaptchaVC.successAction = { [weak hcaptchaVC, weak self] token in
            hcaptchaVC?.dismiss(animated: true) {
                self?.hCaptchaToken = token
                self?.save()
            }
        }

        hcaptchaVC.errorAction = { [weak hcaptchaVC, weak self] error in
            hcaptchaVC?.dismiss(animated: true) {
                self?.hCaptchaToken = nil
                self?.setViewControllerUserInteraction(enabled: true)
                self?.enableProgressiveButtonIfNecessary()
                WMFToastManager.sharedInstance.showErrorAlert(error, sticky: true, dismissPreviousToasts: true)
            }
        }

        present(hcaptchaVC, animated: true) {
            hcaptchaVC.validate()
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
        setupHCaptchaFinePrintText()
    }
}

extension WMFLoginViewController: UITextViewDelegate {
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange) -> Bool {
        if URL.absoluteString.contains("privacy") {
            authInstrument.submitInteraction(action: "click", elementId: "hcaptcha_privacy_link")
        } else if URL.absoluteString.contains("terms") {
            authInstrument.submitInteraction(action: "click", elementId: "hcaptcha_tos_link")
        }
        let config = SinglePageWebViewController.StandardConfig(url: URL, useSimpleNavigationBar: true)
        let inAppWebView = SinglePageWebViewController(configType: .standard(config), theme: theme)
        let navVC = WMFComponentNavigationController(rootViewController: inAppWebView, modalPresentationStyle: .pageSheet)
        present(navVC, animated: true)
        return false
    }
}
