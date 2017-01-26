
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
    
    let tokensFetcher = WMFTokensFetcher()
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
        let siteURL = MWKLanguageLinkController.sharedInstance().appLanguage?.siteURL();
        sendPasswordResetEmail(siteURL: siteURL!, userName: usernameTextField.text, email: emailTextField.text)
    }
    
    func sendPasswordResetEmail(siteURL: URL, userName: String?, email: String?) {

        let failureHandler: WMFURLSessionDataTaskFailureHandler = {
            (_, error: Error) in
            WMFAlertManager.sharedInstance.showAlert(error.localizedDescription, sticky: true, dismissPreviousAlerts: true, tapCallBack: nil)
        }

        let passwordResetterSuccessHandler: WMFURLSessionDataTaskSuccessHandler = {
            (_, response: Any?) in
            WMFAlertManager.sharedInstance.showAlert(localizedStringForKeyFallingBackOnEnglish("forgot-password-email-sent"), sticky: true, dismissPreviousAlerts: true, tapCallBack: nil)
        }
        
        let tokenFetcherSuccessHandler: WMFURLSessionDataTaskSuccessHandler = {
            (_, tokens: Any) in
            let tokens = tokens as! WMFApiTokens
            self.passwordResetter.resetPassword(
                siteURL: siteURL,
                token: tokens.csrf!,
                userName: userName,
                email: email,
                completion: passwordResetterSuccessHandler,
                failure: failureHandler
            )
        }
        
        tokensFetcher.fetchTokens(
            tokens: [.csrf],
            siteURL: siteURL,
            completion: tokenFetcherSuccessHandler,
            failure: failureHandler
        )
    
    }
}
