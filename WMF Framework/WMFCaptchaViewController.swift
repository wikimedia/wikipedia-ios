
import UIKit

// Presently it is assumed this view controller will be used only as a
// child view controller of another view controller.

@objc public protocol WMFCaptchaViewControllerDelegate{
    func captchaReloadPushed(_ sender: AnyObject)
    func captchaSolutionChanged(_ sender: AnyObject, solutionText: String?)
    func captchaSiteURL() -> URL
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

    public var captchaDelegate: WMFCaptchaViewControllerDelegate?
    fileprivate let captchaResetter = WMFCaptchaResetter()

    var captcha: WMFCaptcha? {
        didSet {
            guard let captcha = captcha else {
                captchaTextBox.text = nil
                return;
            }
            captchaTextBox.becomeFirstResponder()
            captchaTextBox.text = ""
            refreshImage(for: captcha)
        }
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
    
    fileprivate func refreshImage(for captcha: WMFCaptcha) {
        guard let fullCaptchaImageURL = fullCaptchaImageURL(from: captcha.captchaURL) else {
            assert(false, "Unable to determine fullCaptchaImageURL")
            return
        }
        captchaImageView.sd_setImage(with: fullCaptchaImageURL)
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
        guard captchaDelegate != nil else{
            assert(false, "Required delegate is unset")
        }
        reloadCaptchaButton.setTitle(localizedStringForKeyFallingBackOnEnglish("captcha-reload"), for: .normal)
        captchaTextBox.placeholder = localizedStringForKeyFallingBackOnEnglish("captcha-prompt")
        reloadCaptchaButton.setTitleColor(UIColor.darkGray, for: .disabled)
        reloadCaptchaButton.setTitleColor(UIColor.darkGray, for: .normal)
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
