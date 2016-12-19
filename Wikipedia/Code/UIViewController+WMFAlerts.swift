import UIKit

extension UIViewController {
    
    func wmf_showAlertWithError(_ error: NSError) {
        let alert = UIAlertController(title: error.localizedDescription, message: error.localizedRecoverySuggestion, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style:.default, handler: nil))
        present(alert, animated: true, completion: nil)
    }
    
}
