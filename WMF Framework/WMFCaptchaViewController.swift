
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
    @IBOutlet fileprivate var captchaTextFieldTitleLabel: UILabel!
    @IBOutlet fileprivate var captchaTextField: UITextField!
    @IBOutlet fileprivate var stackView: UIStackView!
    @IBOutlet fileprivate var titleLabel: UILabel!
    @IBOutlet fileprivate var subTitleLabel: UILabel!
    @IBOutlet fileprivate var topSpacer: UIView!
    @IBOutlet fileprivate var bottomSpacer: UIView!
    @IBOutlet fileprivate var buttonSpacer: UIView!
    @IBOutlet fileprivate var imageSpacer: UIView!
    @IBOutlet fileprivate var infoButton: UIButton!
    @IBOutlet fileprivate var refreshButton: UIButton!
    @IBOutlet fileprivate var imageStackView: UIStackView!
    @IBOutlet fileprivate var buttonStackView: UIStackView!

    public var captchaDelegate: WMFCaptchaViewControllerDelegate?
    fileprivate let captchaResetter = WMFCaptchaResetter()

    var captcha: WMFCaptcha? {
        didSet {
            guard let captcha = captcha else {
                captchaTextField.text = nil
                stackView(collapse:true)
                return;
            }
            stackView(collapse:false)
            captchaTextField.text = ""
            refreshImage(for: captcha)
        }
    }

    fileprivate func stackView(collapse: Bool) {
        captchaImageView.isHidden = collapse
        captchaTextField.isHidden = collapse
        titleLabel.isHidden = collapse
        topSpacer.isHidden = collapse
        bottomSpacer.isHidden = collapse
        refreshButton.isHidden = collapse
        infoButton.isHidden = collapse
        imageStackView.isHidden = collapse
        buttonStackView.isHidden = collapse
        buttonSpacer.isHidden = collapse
        imageSpacer.isHidden = collapse
        captchaTextFieldTitleLabel.isHidden = collapse
        
        guard let captchaDelegate = captchaDelegate else{
            assert(false, "Required delegate is unset")
            return
        }
        subTitleLabel.isHidden = (collapse || captchaDelegate.captchaHideSubtitle())
    }
    
    var solution:String? {
        get{
            guard
                let captchaSolution = captchaTextField.text,
                captchaSolution.characters.count > 0
                else {
                    return nil
            }
            return captchaTextField.text
        }
    }

    public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == captchaTextField {
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
    
    public func captchaTextFieldBecomeFirstResponder() {
        // Reminder: captchaTextField is private so this vc maintains control over the captcha solution.
        captchaTextField.becomeFirstResponder()
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
    
    fileprivate func firstArrangedSubviewWithRequiredNonZeroHeightConstraint() -> UIView? {
        return stackView.arrangedSubviews.first(where: {arrangedSubview in
            let requiredHeightConstraint = arrangedSubview.constraints.first(where: {constraint in
                guard
                    type(of: constraint) == NSLayoutConstraint.self,
                    constraint.firstAttribute == .height,
                    constraint.priority == UILayoutPriorityRequired,
                    constraint.constant != 0
                    else{
                        return false
                }
                return true
            })
            return (requiredHeightConstraint != nil)
        })
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        guard let captchaDelegate = captchaDelegate else{
            assert(false, "Required delegate is unset")
            return
        }
        
        assert(firstArrangedSubviewWithRequiredNonZeroHeightConstraint() == nil, "\n\nAll stackview arrangedSubview height constraints need to have a priority of < 1000 so the stackview can collapse the 'cell' if the arrangedSubview's isHidden property is set to true. This arrangedSubview was determined to have a required height: \(firstArrangedSubviewWithRequiredNonZeroHeightConstraint()). To fix reduce the priority of its height constraint to < 1000.\n\n")
        
        captcha = nil
        captchaTextFieldTitleLabel.text = localizedStringForKeyFallingBackOnEnglish("field-captcha-title")
        captchaTextField.placeholder = localizedStringForKeyFallingBackOnEnglish("field-captcha-placeholder")
        captchaTextField.wmf_addThinBottomBorder()
        titleLabel.text = localizedStringForKeyFallingBackOnEnglish("account-creation-captcha-title")
        
        // Reminder: used a label instead of a button for subtitle because of multi-line string issues with UIButton.
        subTitleLabel.attributedText = subTitleLabel.wmf_authAttributedStringReusingFont(withDollarSignString: localizedStringForKeyFallingBackOnEnglish("account-creation-captcha-cannot-see-image"), substitutionString: localizedStringForKeyFallingBackOnEnglish("account-creation-captcha-request-account"))
        subTitleLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(requestAnAccountTapped(_:))))
    
        subTitleLabel.isHidden = (captcha == nil) || captchaDelegate.captchaHideSubtitle()
        
        view.wmf_configureSubviewsForDynamicType()
    }
    
    func requestAnAccountTapped(_ recognizer: UITapGestureRecognizer) {
        wmf_openExternalUrl(URL.init(string: "https://en.wikipedia.org/wiki/Wikipedia:Request_an_account"))
    }
    
    @IBAction fileprivate func infoButtonTapped(withSender sender: UIButton) {
        wmf_openExternalUrl(URL.init(string: "https://en.wikipedia.org/wiki/Special:Captcha/help"))
    }

    @IBAction fileprivate func refreshButtonTapped(withSender sender: UIButton) {
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
}
