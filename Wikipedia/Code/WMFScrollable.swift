
protocol WMFScrollable {
    var scrollView: UIScrollView! { get }
}

extension WMFScrollable where Self : UIViewController {
    /// Adjusts 'scrollView' contentInset so its contents can be scrolled above the keyboard.
    ///
    /// - Parameter notification: A UIKeyboardWillChangeFrame notification. Works for landscape and portrait.
    func wmf_adjustScrollViewInset(forKeyboardWillChangeFrameNotification notification: Notification) {
        guard
            notification.name == Notification.Name.UIKeyboardWillChangeFrame,
            let keyboardScreenRect = notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? CGRect
            else {
                assert(false, "Notification name was expected to be '\(Notification.Name.UIKeyboardWillChangeFrame)' but was '\(notification.name)'")
                return
        }
        guard let window = view.window else {
            assert(false, "No window")
            return
        }
        let keyboardWindowRect = window.convert(keyboardScreenRect, from: nil)
        let intersection = keyboardWindowRect.intersection(window.frame)
        let contentInsets = UIEdgeInsetsMake(0, 0, intersection.size.height, 0)
        scrollView.contentInset = contentInsets
    }
}
