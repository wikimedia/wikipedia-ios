
import UIKit

fileprivate enum WMFTwoFactorNextFirstResponderDirection: Int {
    case forward = 1
    case reverse = -1
}

fileprivate enum WMFTwoFactorTokenDisplayMode {
    case shortNumeric
    case longAlphaNumeric
}

class WMFTwoFactorPasswordViewController: WMFScrollViewController, UITextFieldDelegate, WMFDeleteBackwardReportingTextFieldDelegate, Themeable {
    
    @IBOutlet fileprivate var titleLabel: UILabel!
    @IBOutlet fileprivate var subTitleLabel: UILabel!
    @IBOutlet fileprivate var tokenLabel: UILabel!
    @IBOutlet fileprivate var tokenAlertLabel: UILabel!
    @IBOutlet fileprivate var oathTokenFields: [ThemeableTextField]!
    @IBOutlet fileprivate var oathTokenFieldsStackView: UIStackView!
    @IBOutlet fileprivate var displayModeToggle: UILabel!
    @IBOutlet fileprivate var backupOathTokenField: ThemeableTextField!
    @IBOutlet fileprivate var loginButton: WMFAuthButton!
    
    fileprivate var theme = Theme.standard
    
    public var funnel: WMFLoginFunnel?
    
    public var userName:String?
    public var password:String?
    public var captchaID:String?
    public var captchaWord:String?
    
    @objc func displayModeToggleTapped(_ recognizer: UITapGestureRecognizer) {
        guard recognizer.state == .ended else {
            return
        }
        switch displayMode {
        case .longAlphaNumeric:
            displayMode = .shortNumeric
        case .shortNumeric:
            displayMode = .longAlphaNumeric
        }
    }

    fileprivate var displayMode: WMFTwoFactorTokenDisplayMode = .shortNumeric {
        didSet {
            switch displayMode {
            case .longAlphaNumeric:
                backupOathTokenField.isHidden = false
                oathTokenFieldsStackView.isHidden = true
                tokenLabel.text = WMFLocalizedString("field-backup-token-title", value:"Backup code", comment:"Title for backup token field")
                displayModeToggle.text = WMFLocalizedString("two-factor-login-with-regular-code", value:"Use verification code", comment:"Button text for showing text fields for normal two factor login")
            case .shortNumeric:
                backupOathTokenField.isHidden = true
                oathTokenFieldsStackView.isHidden = false
                tokenLabel.text = WMFLocalizedString("field-token-title", value:"Verification code", comment:"Title for token field")
                displayModeToggle.text = WMFLocalizedString("two-factor-login-with-backup-code", value:"Use one of your backup codes", comment:"Button text for showing text field for backup code two factor login")
            }
            oathTokenFields.forEach {$0.text = nil}
            backupOathTokenField.text = nil
            if isViewLoaded && (view.window != nil) {
                makeAppropriateFieldFirstResponder()
            }
        }
    }
    
    fileprivate func makeAppropriateFieldFirstResponder() {
        switch displayMode {
        case .longAlphaNumeric:
            backupOathTokenField?.becomeFirstResponder()
        case .shortNumeric:
            oathTokenFields.first?.becomeFirstResponder()
        }
    }
    
    @IBAction fileprivate func loginButtonTapped(withSender sender: UIButton) {
        save()
    }
    
    fileprivate func areRequiredFieldsPopulated() -> Bool {
        switch displayMode {
        case .longAlphaNumeric:
            guard backupOathTokenField.text.wmf_safeCharacterCount > 0 else {
                return false
            }
            return true
        case .shortNumeric:
            return oathTokenFields.first(where:{ $0.text.wmf_safeCharacterCount == 0 }) == nil
        }
    }
    
    @IBAction func textFieldDidChange(_ sender: ThemeableTextField) {
        enableProgressiveButton(areRequiredFieldsPopulated())
        guard
            displayMode == .shortNumeric,
            sender.text.wmf_safeCharacterCount > 0
        else {
            return
        }
        makeNextTextFieldFirstResponder(currentTextField: sender, direction: .forward)
    }
    
    fileprivate func makeNextTextFieldFirstResponder(currentTextField: ThemeableTextField, direction: WMFTwoFactorNextFirstResponderDirection) {
        guard let index = oathTokenFields.firstIndex(of: currentTextField) else {
            return
        }
        let nextIndex = index + direction.rawValue
        guard
            nextIndex > -1,
            nextIndex < oathTokenFields.count
        else {
            return
        }
        oathTokenFields[nextIndex].becomeFirstResponder()
    }
    
    func wmf_deleteBackward(_ sender: WMFDeleteBackwardReportingTextField) {
        guard
            displayMode == .shortNumeric,
            sender.text.wmf_safeCharacterCount == 0
        else {
            return
        }
        makeNextTextFieldFirstResponder(currentTextField: sender, direction: .reverse)
    }
    
    func enableProgressiveButton(_ highlight: Bool) {
        loginButton.isEnabled = highlight
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        enableProgressiveButton(false)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        makeAppropriateFieldFirstResponder()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        enableProgressiveButton(false)
    }
    
    fileprivate func allowedCharacterSet() -> CharacterSet {
        switch displayMode {
        case .longAlphaNumeric:
            return CharacterSet.init(charactersIn: " ").union(CharacterSet.alphanumerics)
        case .shortNumeric:
            return CharacterSet.decimalDigits
        }
    }

    fileprivate func maxTextFieldCharacterCount() -> Int {
        // Presently backup tokens are 16 digit, but may contain spaces and their length 
        // may change in future, so for now just set a sensible upper limit.
        switch displayMode {
        case .longAlphaNumeric:
            return 24
        case .shortNumeric:
            return 1
        }
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        // Disallow invalid characters.
        guard (string.rangeOfCharacter(from: allowedCharacterSet().inverted) == nil) else {
            return false
        }
        // Always allow backspace.
        guard string != "" else {
            return true
        }
        
        // Support numeric code pasting when showing individual digit UITextFields - i.e. when displayMode == .shortNumeric.
        // If displayMode == .shortNumeric 'string' has been verified to be comprised of decimal digits by this point.
        // Backup code (when displayMode == .longAlphaNumeric) pasting already works as-is because it uses a single UITextField.
        if displayMode == .shortNumeric && string.count == oathTokenFields.count{
            for (field, char) in zip(oathTokenFields, string) {
                field.text = String(char)
            }
            enableProgressiveButton(areRequiredFieldsPopulated())
            return false
        }
        
        // Enforce max count.
        let countIfAllowed = textField.text.wmf_safeCharacterCount + string.count
        return (countIfAllowed <= maxTextFieldCharacterCount())
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        tokenAlertLabel.isHidden = true

        // In the storyboard we've set the text fields' to "Clear when editing begins", but
        // the "Editing changed" handler "textFieldDidChange" isn't called when this clearing
        // happens, so update progressive buttons' enabled state here too.
        enableProgressiveButton(areRequiredFieldsPopulated())
    }
    
    public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        guard displayMode == .longAlphaNumeric else {
            return true
        }
        save()
        return true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        oathTokenFields.sort { $0.tag < $1.tag }

        oathTokenFields.forEach {
            $0.rightViewMode = .never
            $0.textAlignment = .center
        }
        
        // Cast fields once here to set 'deleteBackwardDelegate' rather than casting everywhere else UITextField is expected.
        if let fields = oathTokenFields as? [WMFDeleteBackwardReportingTextField] {
            fields.forEach {$0.deleteBackwardDelegate = self}
        }else{
            assertionFailure("Underlying oathTokenFields from storyboard were expected to be of type 'WMFDeleteBackwardReportingTextField'.")
        }
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named:"close"), style: .plain, target:self, action:#selector(closeButtonPushed(_:)))
        navigationItem.leftBarButtonItem?.accessibilityLabel = CommonStrings.closeButtonAccessibilityLabel

        loginButton.setTitle(WMFLocalizedString("two-factor-login-continue", value:"Continue log in", comment:"Button text for finishing two factor login"), for: .normal)
        titleLabel.text = WMFLocalizedString("two-factor-login-title", value:"Log in to your account", comment:"Title for two factor login interface")
        subTitleLabel.text = WMFLocalizedString("two-factor-login-instructions", value:"Please enter two factor verification code", comment:"Instructions for two factor login interface")
        
        displayMode = .shortNumeric

        displayModeToggle.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(displayModeToggleTapped(_:))))

        view.wmf_configureSubviewsForDynamicType()
        
        apply(theme: theme)
    }
    
    @objc func closeButtonPushed(_ : UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
    
    fileprivate func token() -> String {
        switch displayMode {
        case .longAlphaNumeric:
            return backupOathTokenField.text!
        case .shortNumeric:
            return oathTokenFields.reduce("", { $0 + ($1.text ?? "") })
        }
    }
    
    fileprivate func save() {
        wmf_hideKeyboard()
        tokenAlertLabel.isHidden = true
        enableProgressiveButton(false)
        
        guard
            let userName = userName,
            let password = password
        else {
            return
        }
        WMFAlertManager.sharedInstance.showAlert(WMFLocalizedString("account-creation-logging-in", value:"Logging in...", comment:"Alert shown after account successfully created and the user is being logged in automatically. {{Identical|Logging in}}"), sticky: true, dismissPreviousAlerts: true, tapCallBack: nil)

        MWKDataStore.shared().authenticationManager.login(username: userName, password: password, retypePassword: nil, oathToken: token(), captchaID: captchaID, captchaWord: captchaWord) { (loginResult) in
            switch loginResult {
            case .success(_):
                let loggedInMessage = String.localizedStringWithFormat(WMFLocalizedString("main-menu-account-title-logged-in", value:"Logged in as %1$@", comment:"Header text used when account is logged in. %1$@ will be replaced with current username."), userName)
                WMFAlertManager.sharedInstance.showSuccessAlert(loggedInMessage, sticky: false, dismissPreviousAlerts: true, tapCallBack: nil)
                let presenter = self.presentingViewController
                self.dismiss(animated: true, completion: {
                    presenter?.wmf_showEnableReadingListSyncPanel(theme: self.theme, oncePerLogin: true)
                })
                self.funnel?.logSuccess()
            case .failure(let error):
                if let error = error as? WMFAccountLoginError {
                    switch error {
                    case .temporaryPasswordNeedsChange:
                        WMFAlertManager.sharedInstance.dismissAlert()
                        self.showChangeTempPasswordViewController()
                        return
                    case .wrongToken:
                        self.tokenAlertLabel.text = error.localizedDescription
                        self.tokenAlertLabel.isHidden = false
                        self.funnel?.logError(error.localizedDescription)
                        WMFAlertManager.sharedInstance.dismissAlert()
                        return
                    default:
                        break
                    }
                    self.enableProgressiveButton(true)
                    WMFAlertManager.sharedInstance.showErrorAlert(error as NSError, sticky: true, dismissPreviousAlerts: true, tapCallBack: nil)
                    self.funnel?.logError(error.localizedDescription)
                    self.oathTokenFields.forEach {$0.text = nil}
                    self.backupOathTokenField.text = nil
                    self.makeAppropriateFieldFirstResponder()
                }
            default:
                break
            }
        }
    }
    
    func showChangeTempPasswordViewController() {
        guard
            let presenter = presentingViewController,
            let changePasswordVC = WMFChangePasswordViewController.wmf_initialViewControllerFromClassStoryboard()
        else {
            assertionFailure("Expected view controller(s) not found")
            return
        }
        changePasswordVC.apply(theme: theme)
        dismiss(animated: true, completion: {
            changePasswordVC.userName = self.userName
            let navigationController = WMFThemeableNavigationController(rootViewController: changePasswordVC, theme: self.theme)
            presenter.present(navigationController, animated: true, completion: nil)
        })
    }
    
    func apply(theme: Theme) {
        self.theme = theme
        guard viewIfLoaded != nil else {
            return
        }
        
        view.backgroundColor = theme.colors.paperBackground
        view.tintColor = theme.colors.link
        
        tokenAlertLabel.textColor = theme.colors.error
        
        var fields = oathTokenFields ?? []
        fields.append(backupOathTokenField)
        
        for textField in fields {
            textField.apply(theme: theme)
        }
        
        titleLabel.textColor = theme.colors.primaryText
        tokenLabel.textColor = theme.colors.secondaryText
        
        displayModeToggle.textColor = theme.colors.link
        subTitleLabel.textColor = theme.colors.secondaryText
    }
}
