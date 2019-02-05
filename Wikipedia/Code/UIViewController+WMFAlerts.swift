import UIKit

extension UIViewController {
    
    @objc func wmf_showAlertWithError(_ error: NSError) {
        let alert = UIAlertController(title: error.localizedDescription, message: error.localizedRecoverySuggestion, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: CommonStrings.okTitle, style:.default, handler: nil))
        present(alert, animated: true, completion: nil)
    }
    
    @objc func wmf_showAlertWithMessage(_ message: String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: CommonStrings.okTitle, style:.default, handler: nil))
        present(alert, animated: true, completion: nil)
    }
    
}
