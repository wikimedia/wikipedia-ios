
import UIKit

class ForgotPasswordViewController: UIViewController {

    @IBOutlet fileprivate var titleLabel: UILabel!
    @IBOutlet fileprivate var subTitleLabel: UILabel!
    @IBOutlet fileprivate var usernameLabel: UILabel!
    @IBOutlet fileprivate var usernameTextField: UITextField!
    @IBOutlet fileprivate var orLabel: UILabel!
    @IBOutlet fileprivate var emailLabel: UILabel!
    @IBOutlet fileprivate var emailTextField: UITextField!
    @IBOutlet fileprivate var resetButton: UIButton!
    
    let tokenFetcher = WMFAuthTokenFetcher()
    let passwordResetter = WMFPasswordResetter()

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named:"close"), style: .plain, target:self, action:#selector(self.didTapClose(_:)))
    
        titleLabel.text = localizedStringForKeyFallingBackOnEnglish("forgot-password-title")
        subTitleLabel.text = localizedStringForKeyFallingBackOnEnglish("forgot-password-instructions")
        usernameLabel.text = localizedStringForKeyFallingBackOnEnglish("forgot-password-username")
        usernameTextField.placeholder = localizedStringForKeyFallingBackOnEnglish("forgot-password-username-prompt")
        orLabel.text = localizedStringForKeyFallingBackOnEnglish("forgot-password-email-or-username")
        emailLabel.text = localizedStringForKeyFallingBackOnEnglish("forgot-password-email")
        emailTextField.placeholder = localizedStringForKeyFallingBackOnEnglish("forgot-password-email-prompt")
        resetButton.setTitle(localizedStringForKeyFallingBackOnEnglish("forgot-password-button-title"), for: UIControlState())
    }
    
    func didTapClose(_ tap: UITapGestureRecognizer) {
        self.dismiss(animated: true, completion: nil)
    }

    @IBAction fileprivate func didTapResetPasswordButton(withSender sender: UIButton) {
        sendPasswordResetEmail(userName: usernameTextField.text, email: emailTextField.text)
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
                    WMFAlertManager.sharedInstance.showAlert(localizedStringForKeyFallingBackOnEnglish("forgot-password-email-sent"), sticky: true, dismissPreviousAlerts: true, tapCallBack: nil)
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
