
/// Protocol for notifying a delegate that a UITextField's keyboard delete button was pressed even if the text field is empty, which doesn't appear to get reported to other UITextFieldDelegate methods. See: http://stackoverflow.com/a/13017462/135557
@objc public protocol WMFDeleteBackwardReportingTextFieldDelegate{
    func wmf_deleteBackward(_ sender: UITextField)
}

class WMFDeleteBackwardReportingTextField : UITextField {
    
    // Needed this trick http://stackoverflow.com/a/26621912/135557 to connect this IBOutlet delegate via Interface Builder.
    @IBOutlet fileprivate var deleteBackwardDelegate: WMFDeleteBackwardReportingTextFieldDelegate!
    
    override func deleteBackward() {
        deleteBackwardDelegate?.wmf_deleteBackward(self)
        super.deleteBackward()
    }
}
