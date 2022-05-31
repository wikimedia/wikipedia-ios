extension UIViewController {
    /**
     *  Uses the responder chain to make all UIResponders
     *  in the view hierarchy resignFirstResponder.
     */
    @objc func wmf_hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIApplication.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
