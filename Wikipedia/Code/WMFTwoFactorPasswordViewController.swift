
import UIKit

class WMFTwoFactorPasswordViewController: UIViewController {
    
    @IBOutlet fileprivate var titleLabel: UILabel!
    @IBOutlet fileprivate var subTitleLabel: UILabel!
    @IBOutlet fileprivate var oathTokenField: UITextField!
    @IBOutlet fileprivate var oathTokenUnderlineHeight: NSLayoutConstraint!
    
    fileprivate var doneButton: UIBarButtonItem!
    
    public var funnel: LoginFunnel?
    
    public var userName:String?
    public var password:String?
    
    func doneButtonPushed(_ tap: UITapGestureRecognizer) {
        save()
    }
    
    func textFieldDidChange(_ sender: UITextField) {
        enableProgressiveButton((oathTokenField.text!.characters.count > 0))
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
        oathTokenField.becomeFirstResponder()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        enableProgressiveButton(false)
    }
    
    public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if (textField == self.oathTokenField) {
            save()
        }
        return true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named:"close"), style: .plain, target:self, action:#selector(self.didTapClose(_:)))
        
        doneButton = UIBarButtonItem(title: localizedStringForKeyFallingBackOnEnglish("main-menu-account-login"), style: .plain, target: self, action: #selector(self.doneButtonPushed(_:)))
        navigationItem.rightBarButtonItem = doneButton
        
        oathTokenField.addTarget(self, action: #selector(self.textFieldDidChange(_:)), for: .editingChanged)
        
        oathTokenUnderlineHeight.constant = 1.0 / UIScreen.main.scale
        
        titleLabel.text = localizedStringForKeyFallingBackOnEnglish("two-factor-login-title")
        subTitleLabel.text = localizedStringForKeyFallingBackOnEnglish("two-factor-login-instructions")
        oathTokenField.placeholder = localizedStringForKeyFallingBackOnEnglish("two-factor-login-token-placeholder-text")
    }
    
    func didTapClose(_ tap: UITapGestureRecognizer) {
        self.dismiss(animated: true, completion: nil)
    }
    
    fileprivate func save() {
        enableProgressiveButton(false)
        WMFAlertManager.sharedInstance.dismissAlert()
        
        guard
            let userName = userName,
            let password = password
        else {
            return
        }

        WMFAuthenticationManager.sharedInstance()
            .login(withUsername: userName,
                   password: password,
                   retypePassword: nil,
                   oathToken: oathTokenField.text!,
                   success: {
                    let loggedInMessage = localizedStringForKeyFallingBackOnEnglish("main-menu-account-title-logged-in").replacingOccurrences(of: "$1", with: userName)
                    WMFAlertManager.sharedInstance.showSuccessAlert(loggedInMessage, sticky: false, dismissPreviousAlerts: true, tapCallBack: nil)
                    self.dismiss(animated: true, completion: nil)
                    self.funnel?.logSuccess()
            }, failure: { (error: Error) in
                
                if let error = error as? WMFAccountLoginError {
                    switch error.type {
                    case .temporaryPasswordNeedsChange:
                        self.showChangeTempPasswordViewController()
                        return
                    default: break
                    }
                }
                
                self.enableProgressiveButton(true)
                WMFAlertManager.sharedInstance.showErrorAlert(error as NSError, sticky: true, dismissPreviousAlerts: true, tapCallBack: nil)
                self.funnel?.logError(error.localizedDescription)
                self.oathTokenField.text = nil
            })
    }
    
    func showChangeTempPasswordViewController() {
        guard let presenter = self.presentingViewController else {
            return
        }
        dismiss(animated: true, completion: {
            let changePasswordVC = WMFChangePasswordViewController.wmf_initialViewControllerFromClassStoryboard()
            changePasswordVC?.userName = self.userName
            let navigationController = UINavigationController.init(rootViewController: changePasswordVC!)
            presenter.present(navigationController, animated: true, completion: nil)
        })
    }
}
