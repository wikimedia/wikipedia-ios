
import UIKit

fileprivate enum NextFirstResponderDirection: Int {
    case forward = 1
    case reverse = -1
}

class WMFTwoFactorPasswordViewController: WMFScrollViewController, UITextFieldDelegate, WMFDeleteBackwardReportingTextFieldDelegate {
    
    @IBOutlet fileprivate var titleLabel: UILabel!
    @IBOutlet fileprivate var subTitleLabel: UILabel!
    @IBOutlet fileprivate var tokenLabel: UILabel!
    @IBOutlet fileprivate var oathTokenFields: [UITextField]!
    @IBOutlet fileprivate var oathTokenFieldsStackView: UIStackView!
    @IBOutlet fileprivate var backupOathTokenToggle: UILabel!
    @IBOutlet fileprivate var backupOathTokenField: UITextField!
    @IBOutlet fileprivate var loginButton: WMFAuthButton!
    
    public var funnel: LoginFunnel?
    
    public var userName:String?
    public var password:String?
    public var captchaID:String?
    public var captchaWord:String?
    
    func backupOathTokenToggleTapped(_ recognizer: UITapGestureRecognizer) {
        guard recognizer.state == .ended else {
            return
        }
        useBackupOathToken = !useBackupOathToken
    }
    
    fileprivate var useBackupOathToken: Bool = false {
        didSet {
            backupOathTokenField.isHidden = !useBackupOathToken
            oathTokenFieldsStackView.isHidden = useBackupOathToken
            tokenLabel.text = localizedStringForKeyFallingBackOnEnglish(useBackupOathToken ? "field-backup-token-title" : "field-token-title")
            backupOathTokenToggle.text = localizedStringForKeyFallingBackOnEnglish(useBackupOathToken ? "two-factor-login-with-regular-code" : "two-factor-login-with-backup-code")
            oathTokenFields.forEach {$0.text = nil}
            backupOathTokenField.text = nil
            if isViewLoaded && (view.window != nil) {
                makeAppropriateFieldFirstResponder()
            }
        }
    }
    
    
    fileprivate func makeAppropriateFieldFirstResponder() {
        (useBackupOathToken ? backupOathTokenField : oathTokenFields.first)?.becomeFirstResponder()
    }
    
    @IBAction fileprivate func loginButtonTapped(withSender sender: UIButton) {
        save()
    }
    
    fileprivate func areRequiredFieldsPopulated() -> Bool {
        if useBackupOathToken {
            guard let backupToken = backupOathTokenField.text, backupToken.characters.count > 0 else {
                return false
            }
            return true
        }else{
            return oathTokenFields.first(where:{ $0.text?.characters.count == 0 }) == nil
        }
    }
    
    @IBAction func textFieldDidChange(_ sender: UITextField) {
        enableProgressiveButton(areRequiredFieldsPopulated())
        
        guard
            useBackupOathToken == false,
            let text = sender.text, text.characters.count > 0
        else {
            return
        }
        makeNextTextFieldFirstResponder(currentTextField: sender, direction: .forward)
    }
    
    fileprivate func makeNextTextFieldFirstResponder(currentTextField: UITextField, direction: NextFirstResponderDirection) {
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
            useBackupOathToken == false,
            (sender.text ?? "").characters.count == 0
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
        return useBackupOathToken ? CharacterSet.init(charactersIn: " ").union(CharacterSet.alphanumerics) : CharacterSet.decimalDigits
    }

    fileprivate func maxTextFieldCharacterCount() -> Int {
        // Presently backup tokens are 16 digit, but may contain spaces and their length 
        // may change in future, so for now just set a sensible upper limit.
        return useBackupOathToken ? 32 : 1
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
        // Enforce max count.
        let countIfAllowed = (textField.text ?? "" + string).characters.count
        return (countIfAllowed < maxTextFieldCharacterCount())
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        // In the storyboard we've set the text fields' to "Clear when editing begins", but
        // the "Editing changed" handler "textFieldDidChange" isn't called when this clearing
        // happens, so update progressive buttons' enabled state here too.
        enableProgressiveButton(areRequiredFieldsPopulated())
    }
    
    public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        guard useBackupOathToken else {
            return true
        }
        save()
        return true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        oathTokenFields.sort { $0.tag < $1.tag }
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named:"close"), style: .plain, target:self, action:#selector(closeButtonPushed(_:)))
        
        loginButton.setTitle(localizedStringForKeyFallingBackOnEnglish("two-factor-login-continue"), for: .normal)
        
        titleLabel.text = localizedStringForKeyFallingBackOnEnglish("two-factor-login-title")
        subTitleLabel.text = localizedStringForKeyFallingBackOnEnglish("two-factor-login-instructions")
        
        backupOathTokenField.wmf_addThinBottomBorder()
        useBackupOathToken = false
        backupOathTokenToggle.textColor = .wmf_blueTint()
        backupOathTokenToggle.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(backupOathTokenToggleTapped(_:))))

        view.wmf_configureSubviewsForDynamicType()
    }
    
    func closeButtonPushed(_ : UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
    
    fileprivate func token() -> String {
        if useBackupOathToken {
            return backupOathTokenField.text!
        }else{
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
