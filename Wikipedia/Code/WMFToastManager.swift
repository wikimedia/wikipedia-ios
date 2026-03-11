@preconcurrency import WMF
import WMFComponents

@MainActor
open class WMFToastManager: NSObject {

    @objc static let sharedInstance = WMFToastManager()
    var theme = Theme.standard

    // MARK: - Public Convenience Methods (for backward compatibility)

    @objc public func showToast(_ message: String, sticky: Bool, dismissPreviousToasts: Bool, tapCallBack: (@Sendable () -> Void)? = nil) {
        let config = WMFToastConfig(
            title: message,
            duration: sticky ? nil : 2,
            tapAction: tapCallBack
        )
        show(config: config, dismissPreviousToasts: dismissPreviousToasts)
    }

    @objc func showToastWithMessage(_ message: String, subtitle: String?, buttonTitle: String?, image: UIImage?, dismissPreviousToasts: Bool, tapCallBack: (@Sendable () -> Void)? = nil) {
        let config = WMFToastConfig(
            title: message,
            subtitle: subtitle,
            icon: image,
            duration: 10,
            buttonTitle: buttonTitle,
            tapAction: tapCallBack,
            buttonAction: tapCallBack
        )
        show(config: config, dismissPreviousToasts: dismissPreviousToasts)
    }

    @objc func showSuccessToast(_ message: String, sticky: Bool, dismissPreviousToasts: Bool, tapCallBack: (@Sendable () -> Void)?) {
        let config = WMFToastConfig(
            title: message,
            duration: sticky ? nil : 2,
            tapAction: tapCallBack
        )
        show(config: config, dismissPreviousToasts: dismissPreviousToasts)
    }

    @objc func showWarningToast(_ message: String, duration: NSNumber? = nil, sticky: Bool, dismissPreviousToasts: Bool, tapCallBack: (@Sendable () -> Void)? = nil) {
        let finalDuration = duration?.intValue ?? 2
        let config = WMFToastConfig(
            title: message,
            duration: sticky ? nil : TimeInterval(finalDuration),
            tapAction: tapCallBack
        )
        show(config: config, dismissPreviousToasts: dismissPreviousToasts)
    }

    func showWarningToastWithMessageAndSubtitle(_ message: String, subtitle: String?, buttonTitle: String?, image: UIImage?, dismissPreviousToasts: Bool, tapCallBack: (@Sendable () -> Void)? = nil) {
        let config = WMFToastConfig(
            title: message,
            subtitle: subtitle,
            icon: image,
            duration: 10,
            buttonTitle: buttonTitle,
            tapAction: tapCallBack,
            buttonAction: tapCallBack
        )
        show(config: config, dismissPreviousToasts: dismissPreviousToasts)
    }

    @objc func showErrorAlert(_ error: Error, sticky: Bool, dismissPreviousToasts: Bool, tapCallBack: (@Sendable () -> Void)? = nil) {
        let config = WMFToastConfig(
            title: (error as NSError).alertMessage(),
            duration: sticky ? nil : 2,
            tapAction: tapCallBack
        )
        show(config: config, dismissPreviousToasts: dismissPreviousToasts)
    }

    @objc func showErrorToastWithMessage(_ message: String, sticky: Bool, dismissPreviousToasts: Bool, tapCallBack: (@Sendable () -> Void)? = nil) {
        let config = WMFToastConfig(
            title: message,
            duration: sticky ? nil : 2,
            tapAction: tapCallBack
        )
        show(config: config, dismissPreviousToasts: dismissPreviousToasts)
    }

   func showErrorToastWithMessageAndSubtitle(_ message: String, subtitle: String?, buttonTitle: String?, image: UIImage?, dismissPreviousToasts: Bool, tapCallBack: (@Sendable () -> Void)? = nil) {
        let config = WMFToastConfig(
            title: message,
            subtitle: subtitle,
            icon: image,
            duration: 15,
            buttonTitle: buttonTitle,
            tapAction: tapCallBack,
            buttonAction: tapCallBack
        )
        show(config: config, dismissPreviousToasts: dismissPreviousToasts)
    }

    func showToastWithMessage(_ message: String, subtitle: String?, image: UIImage?, duration: TimeInterval? = nil, dismissPreviousToasts: Bool, callback: (@Sendable () -> Void)? = nil, buttonTitle: String? = nil, buttonCallBack: (@Sendable () -> Void)? = nil, completion: (@Sendable () -> Void)? = nil) {
        let config = WMFToastConfig(
            title: message,
            subtitle: subtitle,
            icon: image,
            duration: duration ?? 5,
            buttonTitle: buttonTitle,
            tapAction: callback,
            buttonAction: buttonCallBack
        )
        show(config: config, dismissPreviousToasts: dismissPreviousToasts)

        if let completion = completion, let duration = duration {
            DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                completion()
            }
        }
    }

    // MARK: - Private Methods

    /// Show a toast with the given configuration
    private func show(config: WMFToastConfig, dismissPreviousToasts: Bool) {
        showToast(dismissPreviousToasts) {
            WMFToastPresenter.shared.show(config, dismissPreviousToasts: false)
        }
    }

    private func showToast(_ dismissPreviousToasts: Bool, alertBlock: @escaping () -> Void) {
        if dismissPreviousToasts {
            dismissCurrentToast {
                alertBlock()
            }
        } else {
            alertBlock()
        }
    }

    func dismissCurrentToast(_ completion: @escaping () -> Void = {}) {
        WMFToastPresenter.shared.dismissCurrentToast(completion: completion)
    }

    @objc func dismissCurrentToast() {
        WMFToastPresenter.shared.dismissCurrentToast()
    }
}

extension WMFToastManager: Themeable {

    nonisolated public func apply(theme: Theme) {
        Task { @MainActor in
            self.theme = theme
        }
    }
}
