@preconcurrency import WMF
import WMFComponents
import MessageUI

extension NSError {

    public func toastType() -> WMFToastType {
        if self.wmf_isNetworkConnectionError() {
            return .warning
        } else {
            return .error
        }
    }

}

@MainActor
open class WMFAlertManager: NSObject, Themeable {

    @objc static let sharedInstance = WMFAlertManager()

    var theme = Theme.standard
    nonisolated public func apply(theme: Theme) {
        Task { @MainActor in
            self.theme = theme
        }
    }

    @objc func showAlertWithReadMore(_ title: String?, type: WMFToastType, dismissPreviousAlerts: Bool, buttonCallback: (@Sendable () -> Void)?, tapCallBack: (@Sendable () -> Void)?) {
        showAlert(dismissPreviousAlerts) {
            let config = WMFToastConfig(
                title: title ?? "",
                type: type,
                duration: nil,
                buttonTitle: "Read more",
                tapAction: tapCallBack,
                buttonAction: buttonCallback
            )
            WMFToastPresenter.shared.show(config, dismissPreviousAlerts: false)
        }
    }

    @objc func showAlert(_ message: String?, sticky: Bool, dismissPreviousAlerts: Bool, tapCallBack: (@Sendable () -> Void)? = nil) {
        showAlert(message, sticky: sticky, canBeDismissedByUser: true, dismissPreviousAlerts: dismissPreviousAlerts, tapCallBack: tapCallBack)
    }


    public func showAlert(_ message: String?, sticky: Bool, canBeDismissedByUser: Bool, dismissPreviousAlerts: Bool, tapCallBack: (@Sendable () -> Void)?) {

         if (message ?? "").isEmpty {
             return
         }
         showAlert(dismissPreviousAlerts, alertBlock: { () in
            let config = WMFToastConfig(
                title: message ?? "",
                type: .normal,
                duration: sticky ? nil : 2,
                canBeDismissed: canBeDismissedByUser,
                tapAction: tapCallBack
            )
            WMFToastPresenter.shared.show(config, dismissPreviousAlerts: false)
        })
    }

    @objc func showSuccessAlert(_ message: String, sticky:Bool,dismissPreviousAlerts:Bool, tapCallBack: (@Sendable () -> Void)?) {

        showAlert(dismissPreviousAlerts, alertBlock: { () in
            let config = WMFToastConfig(
                title: message,
                type: .success,
                duration: sticky ? nil : 2,
                tapAction: tapCallBack
            )
            WMFToastPresenter.shared.show(config, dismissPreviousAlerts: false)
        })
    }

    @objc func showWarningAlert(_ message: String, duration: NSNumber? = nil, sticky:Bool,dismissPreviousAlerts:Bool, tapCallBack: (@Sendable () -> Void)? = nil) {

        let finalDuration = duration?.intValue ?? 2

        showAlert(dismissPreviousAlerts, alertBlock: { () in
            let config = WMFToastConfig(
                title: message,
                type: .warning,
                duration: sticky ? nil : TimeInterval(finalDuration),
                tapAction: tapCallBack
            )
            WMFToastPresenter.shared.show(config, dismissPreviousAlerts: false)
        })
    }

    func showErrorAlert(_ error: Error, sticky:Bool, dismissPreviousAlerts:Bool, viewController: UIViewController? = nil, tapCallBack: (@Sendable () -> Void)? = nil) {
        showAlert(dismissPreviousAlerts, alertBlock: { () in
            let config = WMFToastConfig(
                title: (error as NSError).alertMessage(),
                type: .error,
                duration: sticky ? nil : 2,
                tapAction: tapCallBack
            )
            WMFToastPresenter.shared.show(config, dismissPreviousAlerts: false)
        })
    }

    @objc func showErrorAlert(_ error: Error, sticky: Bool, dismissPreviousAlerts:Bool, tapCallBack: (@Sendable () -> Void)? = nil) {
        showErrorAlert(error, sticky: sticky, dismissPreviousAlerts: dismissPreviousAlerts, viewController:nil, tapCallBack: tapCallBack)
    }

    @objc func showErrorAlertWithMessage(_ message: String, sticky:Bool,dismissPreviousAlerts:Bool, tapCallBack: (@Sendable () -> Void)? = nil) {

        showAlert(dismissPreviousAlerts, alertBlock: { () in
            let config = WMFToastConfig(
                title: message,
                type: .error,
                duration: sticky ? nil : 2,
                tapAction: tapCallBack
            )
            WMFToastPresenter.shared.show(config, dismissPreviousAlerts: false)
        })
    }

    @objc func showErrorAlertWithMessage(_ message: String, subtitle: String?, buttonTitle: String?, image: UIImage?, dismissPreviousAlerts:Bool, tapCallBack: (@Sendable () -> Void)? = nil) {
        showAlert(dismissPreviousAlerts, alertBlock: { () in
            let config = WMFToastConfig(
                title: message,
                subtitle: subtitle,
                type: .error,
                icon: image,
                duration: 15,
                buttonTitle: buttonTitle,
                tapAction: tapCallBack,
                buttonAction: tapCallBack
            )
            WMFToastPresenter.shared.show(config, dismissPreviousAlerts: false)
        })
    }

    @objc func showBottomAlertWithMessage(_ message: String, subtitle: String?, buttonTitle: String?, image: UIImage?, dismissPreviousAlerts: Bool, tapCallBack: (@Sendable () -> Void)? = nil) {
        showAlert(dismissPreviousAlerts, alertBlock: { () in
            let config = WMFToastConfig(
                title: message,
                subtitle: subtitle,
                type: .normal,
                icon: image,
                duration: 10,
                buttonTitle: buttonTitle,
                tapAction: tapCallBack,
                buttonAction: tapCallBack
            )
            WMFToastPresenter.shared.show(config, dismissPreviousAlerts: false)
        })
    }

    @objc func showBottomWarningAlertWithMessage(_ message: String, subtitle: String?, buttonTitle: String?, image: UIImage?, dismissPreviousAlerts: Bool, tapCallBack: (@Sendable () -> Void)? = nil) {
        showAlert(dismissPreviousAlerts, alertBlock: { () in
            let config = WMFToastConfig(
                title: message,
                subtitle: subtitle,
                type: .warning,
                icon: image,
                duration: 10,
                buttonTitle: buttonTitle,
                tapAction: tapCallBack,
                buttonAction: tapCallBack
            )
            WMFToastPresenter.shared.show(config, dismissPreviousAlerts: false)
        })
    }

    func showBottomAlertWithMessage(_ message: String, subtitle: String?, image: UIImage?, type: WMFToastType, duration: TimeInterval? = nil, dismissPreviousAlerts: Bool, callback: (@Sendable () -> Void)? = nil, buttonTitle: String? = nil, buttonCallBack: (@Sendable () -> Void)? = nil, completion: (@Sendable () -> Void)? = nil
    ) {
        showAlert(dismissPreviousAlerts) {
            let config = WMFToastConfig(
                title: message,
                subtitle: subtitle,
                type: type,
                icon: image,
                duration: duration ?? 5,
                buttonTitle: buttonTitle,
                tapAction: callback,
                buttonAction: buttonCallBack
            )
            WMFToastPresenter.shared.show(config, dismissPreviousAlerts: false)

            DispatchQueue.main.asyncAfter(deadline: .now() + (duration ?? 5)) {
                completion?()
            }
        }
    }

    private var queuedAlertBlocks: [() -> Void] = []

    @objc func showAlert(_ dismissPreviousAlerts:Bool, alertBlock: @escaping () -> Void) {
        DispatchQueue.main.async {
            if dismissPreviousAlerts {
                self.queuedAlertBlocks.append(alertBlock)
                self.dismissAllAlerts {
                    assert(Thread.isMainThread)
                    if let alertBlock = self.queuedAlertBlocks.popLast() {
                        alertBlock()
                    }
                    self.queuedAlertBlocks.removeAll()
                }
            } else {
                alertBlock()
            }
        }
    }

    @objc func dismissAlert() {
        WMFToastPresenter.shared.dismissCurrentToast()
    }

    @objc func dismissAllAlerts(_ completion: @MainActor @escaping () -> Void = {}) {
        WMFToastPresenter.shared.dismissAll(completion: completion)
    }
}

extension UIImage {
    func resized(to size: CGSize) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(size, false, self.scale)
        self.draw(in: CGRect(origin: .zero, size: size))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return resizedImage
    }
}

