import UIKit

extension UIViewController {
    
    func wmf_showAlertWithError(error: NSError) {
        let alert = UIAlertController(title: error.localizedDescription, message: error.localizedRecoverySuggestion, preferredStyle: .Alert)
        alert.addAction(UIAlertAction(title: "OK", style:.Default, handler: nil))
        presentViewController(alert, animated: true, completion: nil)
    }
    
}
