
protocol WMFScrollable {
    var scrollView: UIScrollView! { get }
}

extension WMFScrollable where Self : UIViewController {
    /// Adjusts 'scrollView' contentInset so its contents can be scrolled above the keyboard.
    ///
    /// - Parameter notification: A UIKeyboardWillChangeFrame notification. Works for landscape and portrait.
    func wmf_adjustScrollViewInset(forKeyboardWillChangeFrameNotification notification: Notification) {
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
    }
    
    func wmf_beginAdjustingScrollViewInsetsForKeyboard() {
        NotificationCenter.default.addObserver(forName: UIWindow.keyboardWillChangeFrameNotification, object: nil, queue: nil, using: { [weak self] notification in
            self?.wmf_adjustScrollViewInset(forKeyboardWillChangeFrameNotification: notification)
        })
    }

    func wmf_endAdjustingScrollViewInsetsForKeyboard() {
        NotificationCenter.default.removeObserver(self, name: UIWindow.keyboardWillChangeFrameNotification, object: nil)
    }
}
