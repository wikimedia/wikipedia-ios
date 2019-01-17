
import UIKit

class WMFScrollViewController: UIViewController {
    @IBOutlet internal var scrollView: UIScrollView!
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        wmf_beginAdjustingScrollViewInsetsForKeyboard()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        wmf_endAdjustingScrollViewInsetsForKeyboard()
        super.viewWillDisappear(animated)
    }
    
    private var coverView: UIView?
    func setViewControllerUserInteraction(enabled: Bool) {
        if enabled {
            coverView?.removeFromSuperview()
        } else if coverView == nil {
            let newCoverView = UIView()
            newCoverView.backgroundColor = view.backgroundColor
            newCoverView.alpha = 0.8
            view.wmf_addSubviewWithConstraintsToEdges(newCoverView)
            coverView = newCoverView
        }
        view.isUserInteractionEnabled = enabled
    }
    
    /// Adjusts 'scrollView' contentInset so its contents can be scrolled above the keyboard.
    ///
    /// - Parameter notification: A UIKeyboardWillChangeFrame notification. Works for landscape and portrait.
    private func wmf_adjustScrollViewInset(forKeyboardWillChangeFrameNotification notification: Notification) {
        guard
            notification.name == UIWindow.keyboardWillChangeFrameNotification,
            let keyboardScreenRect = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect
            else {
                assertionFailure("Notification name was expected to be '\(UIWindow.keyboardWillChangeFrameNotification)' but was '\(notification.name)'")
                return
        }
        guard scrollView != nil else {
            assertionFailure("'scrollView' isn't yet hooked up to a storyboard/nib")
            return
        }
        guard let window = view.window else {
            return
        }
        let keyboardWindowRect = window.convert(keyboardScreenRect, from: nil)
        let intersection = keyboardWindowRect.intersection(window.frame)
        let contentInsets = UIEdgeInsets(top: 0, left: 0, bottom: intersection.size.height, right: 0)
        scrollView.contentInset = contentInsets
        scrollView.scrollIndicatorInsets = contentInsets
    }
    
    private func wmf_beginAdjustingScrollViewInsetsForKeyboard() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillChangeFrame(_:)), name: UIWindow.keyboardWillChangeFrameNotification, object: nil)
    }
    
    private func wmf_endAdjustingScrollViewInsetsForKeyboard() {
        NotificationCenter.default.removeObserver(self, name: UIWindow.keyboardWillChangeFrameNotification, object: nil)
    }
    
    @objc private func keyboardWillChangeFrame(_ notification: Notification) {
        wmf_adjustScrollViewInset(forKeyboardWillChangeFrameNotification: notification)
    }
}
