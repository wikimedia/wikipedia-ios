
import UIKit

// Presently it is assumed this view controller will be used only as a
// child view controller of another view controller.

@objc public protocol WMFCaptchaViewControllerDelegate{
    func captchaReloadPushed(_ sender: AnyObject)
    func captchaSolutionChanged(_ sender: AnyObject, solutionText: String?)
    func captchaLanguageCode() -> String
    func captchaDomain() -> String
}

public class WMFCaptcha: NSObject {
    let captchaID: String
    let captchaURL: URL
    init(captchaID:String, captchaURL:URL) {
        self.captchaID = captchaID
        self.captchaURL = captchaURL
    }
}

class WMFCaptchaViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet fileprivate var captchaImageView: UIImageView!
    @IBOutlet fileprivate var captchaTextBox: UITextField!
    @IBOutlet fileprivate var reloadCaptchaButton: UIButton!

    public var captchaDelegate: WMFCaptchaViewControllerDelegate?
    
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

    fileprivate func refreshImage(for captcha: WMFCaptcha) {
        guard let fullCaptchaImageURL = fullCaptchaImageURL(from: captcha.captchaURL) else {
            assert(false, "Unable to determine fullCaptchaImageURL")
            return
        }
        captchaImageView.sd_setImage(with: fullCaptchaImageURL)
    }
    
    fileprivate func fullCaptchaImageURL(from captchaURL: URL) -> URL? {
        guard let captchaDelegate = captchaDelegate else{
            assert(false, "Required delegate is unset")
            return nil
        }
        guard var components = URLComponents(url: captchaURL, resolvingAgainstBaseURL: false) else {
            assert(false, "Could not extract url components")
            return nil
        }
        components.scheme = "https"
        components.host = "\(captchaDelegate.captchaLanguageCode()).m.\(captchaDelegate.captchaDomain())"
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
