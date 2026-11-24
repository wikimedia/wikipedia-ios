import UIKit
import WMF
import WMFData

@MainActor
enum HCaptchaEditChallengePresenter {

    static let privacyPolicyMessageKey = "hcaptcha-privacy-policy"

    /// Present on the first attempt, or when the server escalates a retry to a visible challenge.
    /// Other repeat requests fall through to the caller's error path, so the user does not loop.
    static func shouldPresent(sentToken: String?, sentForceShowCaptcha: Bool, requirement: WMFHCaptchaRequirement) -> Bool {
        if sentToken == nil {
            return true
        }
        return requirement.forceShowCaptcha && !sentForceShowCaptcha
    }

    static func siteKey(for requirement: WMFHCaptchaRequirement) -> String? {
        if let siteKey = requirement.siteKey {
            return siteKey
        }
        let editApiKey = WMFDeveloperSettingsDataController.shared.loadFeatureConfig()?.ios.hCaptcha?.editApiKey
        return (editApiKey?.isEmpty ?? true) ? nil : editApiKey
    }

    /// `onCancel` runs after the user closes the challenge, and after the error toast for other challenge errors.
    static func present(on presenter: UIViewController, theme: Theme, requirement: WMFHCaptchaRequirement, onSuccess: @escaping (String) -> Void, onCancel: @escaping () -> Void = {}) {
        let hCaptchaViewController = WMFHCaptchaViewController()
        hCaptchaViewController.theme = theme
        hCaptchaViewController.siteKey = siteKey(for: requirement)
        hCaptchaViewController.modalTransitionStyle = .crossDissolve
        hCaptchaViewController.modalPresentationStyle = .overFullScreen

        hCaptchaViewController.successAction = { [weak hCaptchaViewController] token in
            guard let hCaptchaViewController else { return }
            hCaptchaViewController.dismiss(animated: true) {
                onSuccess(token)
            }
        }

        hCaptchaViewController.errorAction = { [weak hCaptchaViewController] error in
            guard let hCaptchaViewController else { return }
            hCaptchaViewController.dismiss(animated: true) {
                if case WMFHCaptchaViewController.CustomError.hCaptchaClosed = error {
                    onCancel()
                    return
                }
                WMFToastManager.sharedInstance.showErrorAlert(error, sticky: true, dismissPreviousToasts: true)
                onCancel()
            }
        }

        presenter.present(hCaptchaViewController, animated: true) {
            hCaptchaViewController.validate()
        }
    }

    /// The localized "protected by hCaptcha" notice, as HTML with links. Nil when the fetch fails.
    static func privacyNoticeHTML(for siteURL: URL) async -> String? {
        let language = WMFLanguage(languageCode: siteURL.wmf_languageCode ?? "en", languageVariantCode: siteURL.wmf_languageVariantCode)
        let messages = try? await MessagesDataController.shared.fetchMessages(keys: [privacyPolicyMessageKey], parseLinks: true, project: .wikipedia(language))
        guard let html = messages?.first(where: { $0.name == privacyPolicyMessageKey })?.content,
              !html.isEmpty else {
            return nil
        }
        return html
    }
}
