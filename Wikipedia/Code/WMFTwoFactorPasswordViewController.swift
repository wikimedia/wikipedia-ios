
import UIKit

fileprivate enum WMFTwoFactorNextFirstResponderDirection: Int {
    case forward = 1
    case reverse = -1
}

fileprivate enum WMFTwoFactorTokenDisplayMode {
    case shortNumeric
    case longAlphaNumeric
}

class WMFTwoFactorPasswordViewController: WMFScrollViewController, UITextFieldDelegate, WMFDeleteBackwardReportingTextFieldDelegate {
    
    @IBOutlet fileprivate var titleLabel: UILabel!
    @IBOutlet fileprivate var subTitleLabel: UILabel!
    @IBOutlet fileprivate var tokenLabel: UILabel!
    @IBOutlet fileprivate var oathTokenFields: [UITextField]!
    @IBOutlet fileprivate var oathTokenFieldsStackView: UIStackView!
    @IBOutlet fileprivate var displayModeToggle: UILabel!
    @IBOutlet fileprivate var backupOathTokenField: UITextField!
    @IBOutlet fileprivate var loginButton: WMFAuthButton!
    
    public var funnel: LoginFunnel?
    
    public var userName:String?
    public var password:String?
    public var captchaID:String?
    public var captchaWord:String?
    
    func displayModeToggleTapped(_ recognizer: UITapGestureRecognizer) {
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
                tokenLabel.text = localizedStringForKeyFallingBackOnEnglish("field-backup-token-title")
                displayModeToggle.text = localizedStringForKeyFallingBackOnEnglish("two-factor-login-with-regular-code")
            case .shortNumeric:
                backupOathTokenField.isHidden = true
                oathTokenFieldsStackView.isHidden = false
                tokenLabel.text = localizedStringForKeyFallingBackOnEnglish("field-token-title")
                displayModeToggle.text = localizedStringForKeyFallingBackOnEnglish("two-factor-login-with-backup-code")
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
    
    @IBAction func textFieldDidChange(_ sender: UITextField) {
        enableProgressiveButton(areRequiredFieldsPopulated())
        guard
            displayMode == .shortNumeric,
            sender.text.wmf_safeCharacterCount > 0
        else {
            return
        }
        makeNextTextFieldFirstResponder(currentTextField: sender, direction: .forward)
    }
    
    fileprivate func makeNextTextFieldFirstResponder(currentTextField: UITextField, direction: WMFTwoFactorNextFirstResponderDirection) {
        guard let index = oathTokenFields.index(of: currentTextField) else {
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
    
    func wmf_deleteBackward(_ sender: UITextField) {
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
        if displayMode == .shortNumeric && string.characters.count == oathTokenFields.count{
            for (field, char) in zip(oathTokenFields, string.characters) {
                field.text = String(char)
            }
            enableProgressiveButton(areRequiredFieldsPopulated())
            return false
        }
        
        // Enforce max count.
        let countIfAllowed = textField.text.wmf_safeCharacterCount + string.characters.count
        return (countIfAllowed <= maxTextFieldCharacterCount())
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
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
        oathTokenFields.forEach {$0.wmf_addThinBottomBorder()}

        navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named:"close"), style: .plain, target:self, action:#selector(closeButtonPushed(_:)))
        
        loginButton.setTitle(localizedStringForKeyFallingBackOnEnglish("two-factor-login-continue"), for: .normal)
        titleLabel.text = localizedStringForKeyFallingBackOnEnglish("two-factor-login-title")
        subTitleLabel.text = localizedStringForKeyFallingBackOnEnglish("two-factor-login-instructions")
        
        backupOathTokenField.wmf_addThinBottomBorder()
        displayMode = .shortNumeric
        displayModeToggle.textColor = .wmf_blueTint()
        displayModeToggle.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(displayModeToggleTapped(_:))))

        view.wmf_configureSubviewsForDynamicType()
    }
    
    func closeButtonPushed(_ : UIBarButtonItem) {
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
        enableProgressiveButton(false)
        
        guard
            let userName = userName,
            let password = password
        else {
            return
        }
        WMFAlertManager.sharedInstance.showAlert(localizedStringForKeyFallingBackOnEnglish("account-creation-logging-in"), sticky: true, dismissPreviousAlerts: true, tapCallBack: nil)

        WMFAuthenticationManager.sharedInstance
            .login(username: userName,
                   password: password,
                   retypePassword: nil,
                   oathToken: token(),
                   captchaID: captchaID,
                   captchaWord: captchaWord,
                   success: { _ in
                    let loggedInMessage = localizedStringForKeyFallingBackOnEnglish("main-menu-account-title-logged-in").replacingOccurrences(of: "$1", with: userName)
                    WMFAlertManager.sharedInstance.showSuccessAlert(loggedInMessage, sticky: false, dismissPreviousAlerts: true, tapCallBack: nil)
                    self.dismiss(animated: true, completion: nil)
                    self.funnel?.logSuccess()
            }, failure: { error in
                
                if let error = error as? WMFAccountLoginError {
                    switch error {
                    case .temporaryPasswordNeedsChange:
                        WMFAlertManager.sharedInstance.dismissAlert()
                        self.showChangeTempPasswordViewController()
                        return
                    default: break
                    }
                }
                
                self.enableProgressiveButton(true)
                WMFAlertManager.sharedInstance.showErrorAlert(error as NSError, sticky: true, dismissPreviousAlerts: true, tapCallBack: nil)
                self.funnel?.logError(error.localizedDescription)
                self.oathTokenFields.forEach {$0.text = nil}
                self.backupOathTokenField.text = nil
                self.makeAppropriateFieldFirstResponder()
            })
    }
    
    func showChangeTempPasswordViewController() {
        guard
            let presenter = presentingViewController,
            let changePasswordVC = WMFChangePasswordViewController.wmf_initialViewControllerFromClassStoryboard()
        else {
            assert(false, "Expected view controller(s) not found")
            return
        }
        dismiss(animated: true, completion: {
            changePasswordVC.userName = self.userName
            let navigationController = UINavigationController.init(rootViewController: changePasswordVC)
            presenter.present(navigationController, animated: true, completion: nil)
        })
    }
}
