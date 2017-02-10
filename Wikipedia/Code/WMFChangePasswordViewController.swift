
import UIKit

class WMFChangePasswordViewController: UIViewController {
    
    @IBOutlet fileprivate var titleLabel: UILabel!
    @IBOutlet fileprivate var subTitleLabel: UILabel!
    @IBOutlet fileprivate var passwordField: UITextField!
    @IBOutlet fileprivate var retypeField: UITextField!
    @IBOutlet fileprivate var passwordUnderlineHeight: NSLayoutConstraint!
    @IBOutlet fileprivate var retypeUnderlineHeight: NSLayoutConstraint!

    fileprivate var doneButton: UIBarButtonItem!
    
    public var funnel: LoginFunnel?

    public var userName:String?
    
    func doneButtonPushed(_ tap: UITapGestureRecognizer) {
        save()
    }

    func textFieldDidChange(_ sender: UITextField) {
        enableProgressiveButton((passwordField.text!.characters.count > 0 && retypeField.text!.characters.count > 0 && passwordField.text == retypeField.text))
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
        passwordField.becomeFirstResponder()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        enableProgressiveButton(false)
    }
    
    public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if (textField == self.passwordField) {
            retypeField.becomeFirstResponder()
        } else if (textField == retypeField) {
            save()
        }
        return true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named:"close"), style: .plain, target:self, action:#selector(self.didTapClose(_:)))
        
        doneButton = UIBarButtonItem(title: localizedStringForKeyFallingBackOnEnglish("button-save"), style: .plain, target: self, action: #selector(self.doneButtonPushed(_:)))
        navigationItem.rightBarButtonItem = doneButton
       
        passwordField.addTarget(self, action: #selector(self.textFieldDidChange(_:)), for: .editingChanged)
        retypeField.addTarget(self, action: #selector(self.textFieldDidChange(_:)), for: .editingChanged)

        passwordUnderlineHeight.constant = 1.0 / UIScreen.main.scale
        retypeUnderlineHeight.constant = 1.0 / UIScreen.main.scale

        titleLabel.text = localizedStringForKeyFallingBackOnEnglish("new-password-title")
        subTitleLabel.text = localizedStringForKeyFallingBackOnEnglish("new-password-instructions")
        passwordField.placeholder = localizedStringForKeyFallingBackOnEnglish("new-password-password-placeholder-text")
        retypeField.placeholder = localizedStringForKeyFallingBackOnEnglish("new-password-confirm-placeholder-text")
    }
    
    func didTapClose(_ tap: UITapGestureRecognizer) {
        self.dismiss(animated: true, completion: nil)
    }
    
    fileprivate func save() {
        enableProgressiveButton(false)
        WMFAlertManager.sharedInstance.dismissAlert()
                
        guard let userName = userName else {
            return
        }
        
        WMFAuthenticationManager.sharedInstance()
            .login(username: userName,
                   password: passwordField.text!,
                   retypePassword: retypeField.text!,
                   oathToken: nil,
                   success: { _ in
                    let loggedInMessage = localizedStringForKeyFallingBackOnEnglish("main-menu-account-title-logged-in").replacingOccurrences(of: "$1", with: userName)
                    WMFAlertManager.sharedInstance.showSuccessAlert(loggedInMessage, sticky: false, dismissPreviousAlerts: true, tapCallBack: nil)
                    self.dismiss(animated: true, completion: nil)
                    self.funnel?.logSuccess()
            }, failure: { (error: Error) in
                self.enableProgressiveButton(true)
                WMFAlertManager.sharedInstance.showErrorAlert(error as NSError, sticky: true, dismissPreviousAlerts: true, tapCallBack: nil)
                self.funnel?.logError(error.localizedDescription)
                self.passwordField.text = nil
                self.retypeField.text = nil
            })
    }
}
