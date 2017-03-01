
import UIKit

// Presently it is assumed this view controller will be used only as a
// child view controller of another view controller.

@objc public protocol WMFCaptchaViewControllerDelegate{
    func captchaReloadPushed(_ sender: AnyObject)
    func captchaSolutionChanged(_ sender: AnyObject, solutionText: String?)
    func captchaSiteURL() -> URL
    func captchaKeyboardReturnKeyTapped()
    func captchaHideSubtitle() -> Bool
}

public class WMFCaptcha: NSObject {
    let captchaID: String
    let captchaURL: URL
    init(captchaID:String, captchaURL:URL) {
        self.captchaID = captchaID
        self.captchaURL = captchaURL
    }
    static func captcha(from requests: [[String : AnyObject]]) -> WMFCaptcha? {
        guard
            let captchaAuthenticationRequest = requests.first(where:{$0["id"]! as! String == "CaptchaAuthenticationRequest"}),
            let fields = captchaAuthenticationRequest["fields"] as? [String : AnyObject],
            let captchaId = fields["captchaId"] as? [String : AnyObject],
            let captchaInfo = fields["captchaInfo"] as? [String : AnyObject],
            let captchaIdValue = captchaId["value"] as? String,
            let captchaInfoValue = captchaInfo["value"] as? String,
            let captchaURL = URL(string: captchaInfoValue)
            else {
                return nil
        }
        return WMFCaptcha(captchaID: captchaIdValue, captchaURL: captchaURL)
    }
}

class WMFCaptchaViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet fileprivate var captchaImageView: UIImageView!
    @IBOutlet fileprivate var captchaTextBox: UITextField!
    @IBOutlet fileprivate var reloadCaptchaButton: UIButton!
    @IBOutlet fileprivate var stackView: UIStackView!
    @IBOutlet fileprivate var titleLabel: UILabel!
    @IBOutlet fileprivate var subTitleLabel: UILabel!

    public var captchaDelegate: WMFCaptchaViewControllerDelegate?
    fileprivate let captchaResetter = WMFCaptchaResetter()

    var captcha: WMFCaptcha? {
        didSet {
            guard let captcha = captcha else {
                captchaTextBox.text = nil
                stackView(collapse:true)
                return;
            }
            stackView(collapse:false)
            captchaTextBox.text = ""
            refreshImage(for: captcha)
        }
    }

    fileprivate func stackView(collapse: Bool) {
        captchaImageView.isHidden = collapse
        captchaTextBox.isHidden = collapse
        reloadCaptchaButton.isHidden = collapse
        titleLabel.isHidden = collapse
        
        guard let captchaDelegate = captchaDelegate else{
            assert(false, "Required delegate is unset")
            return
        }
        subTitleLabel.isHidden = (collapse || captchaDelegate.captchaHideSubtitle())
    }
    
    var solution:String? {
        get{
            guard
                let captchaSolution = captchaTextBox.text,
                captchaSolution.characters.count > 0
                else {
                    return nil
            }
            return captchaTextBox.text
        }
    }

    public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == captchaTextBox {
            guard let captchaDelegate = captchaDelegate else {
                assert(false, "Expected delegate not set")
                return true
            }
            captchaDelegate.captchaKeyboardReturnKeyTapped()
        }
        return true
    }
    
    fileprivate func refreshImage(for captcha: WMFCaptcha) {
        guard let fullCaptchaImageURL = fullCaptchaImageURL(from: captcha.captchaURL) else {
            assert(false, "Unable to determine fullCaptchaImageURL")
            return
        }
        captchaImageView.sd_setImage(with: fullCaptchaImageURL)
    }
    
    public func captchaTextBoxBecomeFirstResponder() {
        // Reminder: captchaTextBox is private so this vc maintains control over the captcha solution.
        captchaTextBox.becomeFirstResponder()
    }

    fileprivate func fullCaptchaImageURL(from captchaURL: URL) -> URL? {
        guard let components = URLComponents(url: captchaURL, resolvingAgainstBaseURL: false) else {
            assert(false, "Could not extract url components")
            return nil
        }
        return components.url(relativeTo: captchaBaseURL())
    }
    
    fileprivate func captchaBaseURL() -> URL? {
        guard let captchaDelegate = captchaDelegate else {
            assert(false, "Expected delegate not set")
            return nil
        }
        let captchaSiteURL = captchaDelegate.captchaSiteURL()
        guard var components = URLComponents(url: captchaSiteURL, resolvingAgainstBaseURL: false) else {
            assert(false, "Could not extract url components")
            return nil
        }
        components.queryItems = nil
        guard let url = components.url else{
            assert(false, "Could not extract url")
            return nil
        }
        return url
    }
    
    @IBAction func textFieldDidChange(_ sender: UITextField) {
        captchaDelegate?.captchaSolutionChanged(self, solutionText:sender.text)
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        guard let captchaDelegate = captchaDelegate else{
            assert(false, "Required delegate is unset")
            return
        }
        
        captcha = nil
        reloadCaptchaButton.setTitle(localizedStringForKeyFallingBackOnEnglish("captcha-reload"), for: .normal)
        captchaTextBox.placeholder = localizedStringForKeyFallingBackOnEnglish("captcha-prompt")
        reloadCaptchaButton.setTitleColor(UIColor.darkGray, for: .disabled)
        reloadCaptchaButton.setTitleColor(UIColor.darkGray, for: .normal)
        
        titleLabel.text = localizedStringForKeyFallingBackOnEnglish("account-creation-captcha-title")
        
        // Reminder: used a label instead of a button for subtitle because of multi-line string issues with UIButton.
        subTitleLabel.attributedText = subTitleAttributedString
        subTitleLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(requestAnAccountTapped(_:))))
    
        subTitleLabel.isHidden = (captcha == nil) || captchaDelegate.captchaHideSubtitle()
    }
    
    func requestAnAccountTapped(_ recognizer: UITapGestureRecognizer) {
        wmf_openExternalUrl(URL.init(string: "https://en.wikipedia.org/wiki/Wikipedia:Request_an_account"))
    }

    fileprivate var subTitleAttributedString: NSAttributedString {
        get {
            // Note: uses the font from the storyboard so the attributed string respects the
            // storyboard dynamic type font choice and responds to dynamic type size changes.
            let attributes: [String : Any] = [
                NSFontAttributeName : subTitleLabel.font
            ]
            let substitutionAttributes: [String : Any] = [
                NSForegroundColorAttributeName : UIColor.wmf_blueTint()
            ]
            let cannotSeeImageText = localizedStringForKeyFallingBackOnEnglish("account-creation-captcha-cannot-see-image")
            let requestAccountText = localizedStringForKeyFallingBackOnEnglish("account-creation-captcha-request-account")
            return cannotSeeImageText.attributedString(attributes: attributes, substitutionStrings: [requestAccountText], substitutionAttributes: [substitutionAttributes])
        }
    }
    
    func captchaReloadPushed(_ sender: AnyObject) {
        captchaDelegate?.captchaReloadPushed(self)
                
        let failure: WMFErrorHandler = {error in }
        
        WMFAlertManager.sharedInstance.showAlert(localizedStringForKeyFallingBackOnEnglish("account-creation-captcha-obtaining"), sticky: false, dismissPreviousAlerts: true, tapCallBack: nil)
        
        self.captchaResetter.resetCaptcha(siteURL: captchaBaseURL()!, success: { result in
            guard let previousCaptcha = self.captcha else {
                assert(false, "If resetting a captcha, expect to have a previous one here")
                return
            }
            
            let previousCaptchaURL = previousCaptcha.captchaURL
            let previousCaptchaNSURL = previousCaptchaURL as NSURL
            
            let newCaptchaID = result.index
            
            // Resetter only fetches captchaID, so use previous captchaURL changing its wpCaptchaId.
            let newCaptchaURL = previousCaptchaNSURL.wmf_url(withValue: newCaptchaID, forQueryKey:"wpCaptchaId")
            let newCaptcha = WMFCaptcha.init(captchaID: newCaptchaID, captchaURL: newCaptchaURL)
            self.captcha = newCaptcha
            
        }, failure:failure)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        reloadCaptchaButton.addTarget(self, action: #selector(captchaReloadPushed(_:)), for: .touchUpInside)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        reloadCaptchaButton.removeTarget(nil, action: nil, for: .allEvents)
        super.viewWillDisappear(animated)
    }
}
