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

    @objc func wmf_showAlert(title: String?, message: String?, actions: [UIAlertAction], completion: (() -> Void)? = nil) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        actions.forEach { action in alert.addAction(action) }
        present(alert, animated: true, completion: completion)
    }
    
    func showError(_ error: Error, sticky: Bool = false) {
        WMFAlertManager.sharedInstance.showErrorAlert(error, sticky: sticky, dismissPreviousAlerts: false, viewController: self)
    }

    func showGenericError() {
        showError(RequestError.unknown)
    }
    
}
