
import UIKit

// Presently it is assumed this view controller will be used only as a
// child view controller of another view controller.

@objc public protocol CaptchaViewControllerRefresh{
    func reloadCaptchaPushed(_ sender: AnyObject)
}

class CaptchaViewController: UIViewController {

    @IBOutlet var captchaImageView: UIImageView!
    @IBOutlet var captchaTextBox: UITextField!
    @IBOutlet fileprivate var reloadCaptchaButton: UIButton!

    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        reloadCaptchaButton.setTitle(localizedStringForKeyFallingBackOnEnglish("captcha-reload"), for: .normal)
        captchaTextBox.placeholder = localizedStringForKeyFallingBackOnEnglish("captcha-prompt")
        reloadCaptchaButton.setTitleColor(UIColor.darkGray, for: .disabled)
        reloadCaptchaButton.setTitleColor(UIColor.darkGray, for: .normal)
    }
    
    func reloadCaptchaPushed(_ sender: AnyObject) {
        if self.parent!.responds(to: #selector(reloadCaptchaPushed(_:))) {
            self.parent!.performSelector(onMainThread: #selector(reloadCaptchaPushed(_:)), with: nil, waitUntilDone: true)
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        reloadCaptchaButton.addTarget(self, action: #selector(reloadCaptchaPushed(_:)), for: .touchUpInside)

        // Allow whatever view controller is using this captcha view controller
        // to monitor changes to captchaTextBox and also when its keyboard done/next
        // buttons are tapped.
        
        if self.parent!.conforms(to: CaptchaViewControllerRefresh.self){
            captchaTextBox.delegate = self.parent as? UITextFieldDelegate
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        captchaTextBox.delegate = nil
        self.reloadCaptchaButton.removeTarget(nil, action: nil, for: .allEvents)
        super.viewWillDisappear(animated)
    }
}
