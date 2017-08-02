
/// Protocol for notifying a delegate that a UITextField's keyboard delete button 
/// was pressed even if the text field is empty, which doesn't appear to get 
/// reported to other UITextFieldDelegate methods. 
/// See: http://stackoverflow.com/a/13017462/135557
public protocol WMFDeleteBackwardReportingTextFieldDelegate{
    func wmf_deleteBackward(_ sender: WMFDeleteBackwardReportingTextField)
}

public class WMFDeleteBackwardReportingTextField : ThemeableTextField {
    var deleteBackwardDelegate: WMFDeleteBackwardReportingTextFieldDelegate?
    override public func deleteBackward() {
        deleteBackwardDelegate?.wmf_deleteBackward(self)
        super.deleteBackward()
    }
}
