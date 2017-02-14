
import UIKit

// Presently it is assumed this view controller will be used only as a
// child view controller of another view controller.

@objc public protocol WMFCaptchaViewControllerRefresh{
    func reloadCaptchaPushed(_ sender: AnyObject)
}

class WMFCaptchaViewController: UIViewController {

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
        guard let parentVC = parent else{
            assert(false, "Expected parent view controller not found")
            return
        }
        if parentVC.responds(to: #selector(reloadCaptchaPushed(_:))) {
            parentVC.performSelector(onMainThread: #selector(reloadCaptchaPushed(_:)), with: nil, waitUntilDone: true)
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        reloadCaptchaButton.addTarget(self, action: #selector(reloadCaptchaPushed(_:)), for: .touchUpInside)

        guard let parentVC = parent else{
            assert(false, "Expected parent view controller not found")
            return
        }

        // Allow whatever view controller is using this captcha view controller
        // to monitor changes to captchaTextBox and also when its keyboard done/next
        // buttons are tapped.
        
        if parentVC.conforms(to: WMFCaptchaViewControllerRefresh.self){
            captchaTextBox.delegate = parent as? UITextFieldDelegate
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        captchaTextBox.delegate = nil
        reloadCaptchaButton.removeTarget(nil, action: nil, for: .allEvents)
        super.viewWillDisappear(animated)
    }
}
