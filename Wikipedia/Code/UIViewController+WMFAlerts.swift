import UIKit

extension UIViewController {
    
    @objc func wmf_showAlertWithError(_ error: NSError) {
        let alert = UIAlertController(title: error.localizedDescription, message: error.localizedRecoverySuggestion, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: WMFLocalizedString("button-ok", value:"OK", comment:"Button text for ok button used in various places\n{{Identical|OK}}"), style:.default, handler: nil))
        present(alert, animated: true, completion: nil)
    }
    
    @objc func wmf_showAlertWithMessage(_ message: String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: WMFLocalizedString("button-ok", value:"OK", comment:"Button text for ok button used in various places\n{{Identical|OK}}"), style:.default, handler: nil))
        present(alert, animated: true, completion: nil)
    }
    
}
