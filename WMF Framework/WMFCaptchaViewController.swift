
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
        guard
            let parentVC = parent,
            parentVC.responds(to: #selector(reloadCaptchaPushed(_:)))
        else{
            assert(false, "Expected parent view controller not found or does't respond to 'reloadCaptchaPushed'")
            return
        }
        parentVC.performSelector(onMainThread: #selector(reloadCaptchaPushed(_:)), with: nil, waitUntilDone: true)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        reloadCaptchaButton.addTarget(self, action: #selector(reloadCaptchaPushed(_:)), for: .touchUpInside)

        guard
            let parentVC = parent,
            parentVC.conforms(to: WMFCaptchaViewControllerRefresh.self)
        else{
            assert(false, "Expected parent view controller not found or doesn't conform to WMFCaptchaViewControllerRefresh")
            return
        }

        // Allow whatever view controller is using this captcha view controller
        // to monitor changes to captchaTextBox and also when its keyboard done/next
        // buttons are tapped.
        captchaTextBox.delegate = parent as? UITextFieldDelegate
    
        view.wmf_configureSubviewsForDynamicType()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        captchaTextBox.delegate = nil
        reloadCaptchaButton.removeTarget(nil, action: nil, for: .allEvents)
        super.viewWillDisappear(animated)
    }
}
