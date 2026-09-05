@preconcurrency import WMF
import WMFComponents

@MainActor
final class WMFToastManager: NSObject {

    @objc static let sharedInstance = WMFToastManager()

    // MARK: - Public API

    @objc public func showToast(_ message: String, sticky: Bool, dismissPreviousToasts: Bool, tapCallBack: (() -> Void)? = nil) {
        let config = WMFToastConfig(title: message, duration: sticky ? 10 : 5, tapAction: tapCallBack)
        dismissCurrentToast {
            WMFToastPresenter.shared.show(config)
        }
    }

    @objc(showRichToast:subtitle:buttonTitle:image:duration:dismissPreviousToasts:tapCallBack:buttonCallBack:completion:)
    func showRichToast(_ message: String, subtitle: String? = nil, buttonTitle: String? = nil, image: UIImage? = nil, duration: NSNumber? = NSNumber(value: 5), dismissPreviousToasts: Bool = true, tapCallBack: (() -> Void)? = nil, buttonCallBack: (() -> Void)? = nil, completion: (() -> Void)? = nil) {
        let resolvedDuration: TimeInterval? = duration.map { TimeInterval($0.doubleValue) }
        let config = WMFToastConfig(title: message, subtitle: subtitle, icon: image, duration: resolvedDuration, buttonTitle: buttonTitle, tapAction: tapCallBack, buttonAction: buttonCallBack)
        dismissCurrentToast {
            // The presenter calls the completion when the toast leaves the screen,
            // for any reason: the timer, a swipe, or a replacement.
            WMFToastPresenter.shared.show(config) { _ in
                completion?()
            }
        }
    }

    @objc func showErrorAlert(_ error: Error, sticky: Bool, dismissPreviousToasts: Bool, tapCallBack: (() -> Void)? = nil) {
        let config = WMFToastConfig(title: (error as NSError).alertMessage(), duration: sticky ? 10 : 5, tapAction: tapCallBack)
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
