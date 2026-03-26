@preconcurrency import WMF
import WMFComponents

@MainActor
final class WMFToastManager: NSObject {

    @objc static let sharedInstance = WMFToastManager()
    var theme = Theme.standard

    // MARK: - Public API

    @objc public func showToast(_ message: String, sticky: Bool, dismissPreviousToasts: Bool, tapCallBack: (() -> Void)? = nil) {
        let config = WMFToastConfig(title: message, duration: sticky ? nil : 5, tapAction: tapCallBack)
        dismissCurrentToast {
            WMFToastPresenter.shared.show(config)
        }
    }

    @objc(showRichToast:subtitle:buttonTitle:image:duration:dismissPreviousToasts:tapCallBack:buttonCallBack:completion:)
    func showRichToast(_ message: String, subtitle: String? = nil, buttonTitle: String? = nil, image: UIImage? = nil, duration: NSNumber? = NSNumber(value: 5), dismissPreviousToasts: Bool = true, tapCallBack: (() -> Void)? = nil, buttonCallBack: (() -> Void)? = nil, completion: (() -> Void)? = nil) {
        let resolvedDuration: TimeInterval? = duration.map { TimeInterval($0.doubleValue) }
        let config = WMFToastConfig(title: message, subtitle: subtitle, icon: image, duration: resolvedDuration, buttonTitle: buttonTitle, tapAction: tapCallBack, buttonAction: buttonCallBack)
        dismissCurrentToast {
            WMFToastPresenter.shared.show(config)
        }
        if let completion, let resolvedDuration, resolvedDuration > 0 {
            DispatchQueue.main.asyncAfter(deadline: .now() + resolvedDuration) {
                completion()
            }
        }
    }

    @objc func showErrorAlert(_ error: Error, sticky: Bool, dismissPreviousToasts: Bool, tapCallBack: (() -> Void)? = nil) {
        let config = WMFToastConfig(title: (error as NSError).alertMessage(), duration: sticky ? nil : 5, tapAction: tapCallBack)
        dismissCurrentToast {
            WMFToastPresenter.shared.show(config)
        }
    }

    // MARK: - Private Methods

    @objc func dismissCurrentToast() {
        WMFToastPresenter.shared.dismissCurrentToast()
    }

    private func dismissCurrentToast(completion: @escaping () -> Void) {
        WMFToastPresenter.shared.dismissCurrentToast(completion: completion)
    }
}

extension WMFToastManager: Themeable {

    nonisolated public func apply(theme: Theme) {
        Task { @MainActor in
            self.theme = theme
        }
    }
}
