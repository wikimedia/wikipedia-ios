
import UIKit

class ForgotPasswordViewController: UIViewController {

    @IBOutlet fileprivate var titleLabel: UILabel!
    @IBOutlet fileprivate var subTitleLabel: UILabel!
    @IBOutlet fileprivate var usernameField: UITextField!
    @IBOutlet fileprivate var emailField: UITextField!
    @IBOutlet fileprivate var usernameUnderlineHeight: NSLayoutConstraint!
    @IBOutlet fileprivate var emailUnderlineHeight: NSLayoutConstraint!

    fileprivate var resetButton: UIBarButtonItem!

    let tokenFetcher = WMFAuthTokenFetcher()
    let passwordResetter = WMFPasswordResetter()

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named:"close"), style: .plain, target:self, action:#selector(self.didTapClose(_:)))
    
        titleLabel.text = localizedStringForKeyFallingBackOnEnglish("forgot-password-title")
        subTitleLabel.text = localizedStringForKeyFallingBackOnEnglish("forgot-password-instructions")
        usernameField.placeholder = localizedStringForKeyFallingBackOnEnglish("forgot-password-username-prompt")
        emailField.placeholder = localizedStringForKeyFallingBackOnEnglish("forgot-password-email-prompt")
        
        resetButton = UIBarButtonItem(title: localizedStringForKeyFallingBackOnEnglish("forgot-password-button-title"), style: .plain, target: self, action: #selector(self.resetButtonPushed(_:)))
        navigationItem.rightBarButtonItem = resetButton
    
        usernameField.addTarget(self, action: #selector(self.textFieldDidChange(_:)), for: .editingChanged)
        emailField.addTarget(self, action: #selector(self.textFieldDidChange(_:)), for: .editingChanged)
    
        usernameUnderlineHeight.constant = 1.0 / UIScreen.main.scale
        emailUnderlineHeight.constant = 1.0 / UIScreen.main.scale
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
            emailField.becomeFirstResponder()
        } else if (textField == emailField) {
            save()
        }
        return true
    }

    func textFieldDidChange(_ sender: UITextField) {
        enableProgressiveButton((usernameField.text!.characters.count > 0 || emailField.text!.characters.count > 0))
    }

    func enableProgressiveButton(_ highlight: Bool) {
        resetButton.isEnabled = highlight
    }

    func resetButtonPushed(_ tap: UITapGestureRecognizer) {
        save()
    }

    fileprivate func save() {
        sendPasswordResetEmail(userName: usernameField.text, email: emailField.text)
    }
    
    func didTapClose(_ tap: UITapGestureRecognizer) {
        self.dismiss(animated: true, completion: nil)
    }
    
    func sendPasswordResetEmail(userName: String?, email: String?) {
        guard let siteURL = MWKLanguageLinkController.sharedInstance().appLanguage?.siteURL() else {
            WMFAlertManager.sharedInstance.showAlert("No site url", sticky: true, dismissPreviousAlerts: true, tapCallBack: nil)
            return
        }
        
        tokenFetcher.fetchToken(ofType: .csrf, siteURL: siteURL, completion: {
            (info: WMFAuthToken) in
            self.passwordResetter.resetPassword(
                siteURL: siteURL,
                token: info.token,
                userName: userName,
                email: email,
                completion: {
                    (result: WMFPasswordResetterResult) in                    
                    self.dismiss(animated: true, completion:nil)
                    WMFAlertManager.sharedInstance.showSuccessAlert(localizedStringForKeyFallingBackOnEnglish("forgot-password-email-sent"), sticky: true, dismissPreviousAlerts: true, tapCallBack: nil)
            },
                failure: {
                    (error: Error) in
                    WMFAlertManager.sharedInstance.showAlert(error.localizedDescription, sticky: true, dismissPreviousAlerts: true, tapCallBack: nil)
            })
        }, failure: {
            (error: Error) in
            WMFAlertManager.sharedInstance.showAlert(error.localizedDescription, sticky: true, dismissPreviousAlerts: true, tapCallBack: nil)
        })
    }
}
