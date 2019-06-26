
import Foundation

extension UITextView {
    func frame(of textRange: NSRange) -> CGRect? {
        selectedRange = textRange
        
        var rect: CGRect?
        if let uiTextRange = selectedTextRange {
            rect = firstRect(for: uiTextRange)
        }
        
        selectedRange = NSRange(location: 0, length: 0)
        return rect
    }
}
