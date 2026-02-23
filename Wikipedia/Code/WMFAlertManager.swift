@preconcurrency import WMF
import WMFComponents

@MainActor
open class WMFAlertManager: NSObject {

    @objc static let sharedInstance = WMFAlertManager()
    var theme = Theme.standard

    // MARK: - Public Convenience Methods (for backward compatibility)

    @objc public func showAlert(_ message: String, sticky: Bool, dismissPreviousAlerts: Bool, tapCallBack: (@Sendable () -> Void)? = nil) {
        let config = WMFToastConfig(
            title: message,
            duration: sticky ? nil : 2,
            tapAction: tapCallBack
        )
        show(config: config, dismissPreviousAlerts: dismissPreviousAlerts)
    }

    @objc func showAlertWithMessage(_ message: String, subtitle: String?, buttonTitle: String?, image: UIImage?, dismissPreviousAlerts: Bool, tapCallBack: (@Sendable () -> Void)? = nil) {
        let config = WMFToastConfig(
            title: message,
            subtitle: subtitle,
            icon: image,
            duration: 10,
            buttonTitle: buttonTitle,
            tapAction: tapCallBack,
            buttonAction: tapCallBack
        )
        show(config: config, dismissPreviousAlerts: dismissPreviousAlerts)
    }

    @objc func showSuccessAlert(_ message: String, sticky: Bool, dismissPreviousAlerts: Bool, tapCallBack: (@Sendable () -> Void)?) {
        let config = WMFToastConfig(
            title: message,
            duration: sticky ? nil : 2,
            tapAction: tapCallBack
        )
        show(config: config, dismissPreviousAlerts: dismissPreviousAlerts)
    }

    @objc func showWarningAlert(_ message: String, duration: NSNumber? = nil, sticky: Bool, dismissPreviousAlerts: Bool, tapCallBack: (@Sendable () -> Void)? = nil) {
        let finalDuration = duration?.intValue ?? 2
        let config = WMFToastConfig(
            title: message,
            duration: sticky ? nil : TimeInterval(finalDuration),
            tapAction: tapCallBack
        )
        show(config: config, dismissPreviousAlerts: dismissPreviousAlerts)
    }

    func showWarningAlertWithMessageAndSubtitle(_ message: String, subtitle: String?, buttonTitle: String?, image: UIImage?, dismissPreviousAlerts: Bool, tapCallBack: (@Sendable () -> Void)? = nil) {
        let config = WMFToastConfig(
            title: message,
            subtitle: subtitle,
            icon: image,
            duration: 10,
            buttonTitle: buttonTitle,
            tapAction: tapCallBack,
            buttonAction: tapCallBack
        )
        show(config: config, dismissPreviousAlerts: dismissPreviousAlerts)
    }

    @objc func showErrorAlert(_ error: Error, sticky: Bool, dismissPreviousAlerts: Bool, tapCallBack: (@Sendable () -> Void)? = nil) {
        let config = WMFToastConfig(
            title: (error as NSError).alertMessage(),
            duration: sticky ? nil : 2,
            tapAction: tapCallBack
        )
        show(config: config, dismissPreviousAlerts: dismissPreviousAlerts)
    }

    @objc func showErrorAlertWithMessage(_ message: String, sticky: Bool, dismissPreviousAlerts: Bool, tapCallBack: (@Sendable () -> Void)? = nil) {
        let config = WMFToastConfig(
            title: message,
            duration: sticky ? nil : 2,
            tapAction: tapCallBack
        )
        show(config: config, dismissPreviousAlerts: dismissPreviousAlerts)
    }

   func showErrorAlertWithMessageAndSubtitle(_ message: String, subtitle: String?, buttonTitle: String?, image: UIImage?, dismissPreviousAlerts: Bool, tapCallBack: (@Sendable () -> Void)? = nil) {
        let config = WMFToastConfig(
            title: message,
            subtitle: subtitle,
            icon: image,
            duration: 15,
            buttonTitle: buttonTitle,
            tapAction: tapCallBack,
            buttonAction: tapCallBack
        )
        show(config: config, dismissPreviousAlerts: dismissPreviousAlerts)
    }

    func showAlertWithMessage(_ message: String, subtitle: String?, image: UIImage?, duration: TimeInterval? = nil, dismissPreviousAlerts: Bool, callback: (@Sendable () -> Void)? = nil, buttonTitle: String? = nil, buttonCallBack: (@Sendable () -> Void)? = nil, completion: (@Sendable () -> Void)? = nil) {
        let config = WMFToastConfig(
            title: message,
            subtitle: subtitle,
            icon: image,
            duration: duration ?? 5,
            buttonTitle: buttonTitle,
            tapAction: callback,
            buttonAction: buttonCallBack
        )
        show(config: config, dismissPreviousAlerts: dismissPreviousAlerts)

        if let completion = completion, let duration = duration {
            DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                completion()
            }
        }
    }

    // MARK: - Private Methods

    private var queuedAlertBlocks: [() -> Void] = []

    /// Show a toast with the given configuration
    private func show(config: WMFToastConfig, dismissPreviousAlerts: Bool) {
        showAlert(dismissPreviousAlerts) {
            WMFToastPresenter.shared.show(config, dismissPreviousAlerts: false)
        }
    }

    private func showAlert(_ dismissPreviousAlerts: Bool, alertBlock: @escaping () -> Void) {
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

extension WMFAlertManager: Themeable {

    nonisolated public func apply(theme: Theme) {
        Task { @MainActor in
            self.theme = theme
        }
    }
}
