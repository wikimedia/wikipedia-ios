import Foundation

extension UIViewController {
    func showError(_ error: Error, sticky: Bool = false) {
        WMFAlertManager.sharedInstance.showErrorAlert(error, sticky: sticky, dismissPreviousAlerts: false, viewController: self)
    }

    func showGenericError() {
        showError(RequestError.unknown)
    }
}
