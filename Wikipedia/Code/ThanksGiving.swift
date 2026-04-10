import Foundation
import WMF
import WMFNativeLocalizations
import WMFComponents

protocol ThanksGiving: AnyObject {
    var url: URL? { get }
    func didLogIn()
    func wereThanksSent(for revisionID: Int) -> Bool
    func thanksWereSent(for revisionID: Int)
}

enum ThanksGivingSource {
    case diff
    case unknown
}

extension ThanksGiving where Self: ThemeableViewController {

    var source: ThanksGivingSource {

        switch self {
        case is DiffContainerViewController:
            return .diff
        default:
            return .unknown
        }
    }

    var isPermanent: Bool {
        // SINGLETONTODO
        return MWKDataStore.shared().authenticationManager.authStateIsPermanent
    }

    func tappedThank(for revisionID: Int?, isUserAnonymous: Bool) {
        guard let revisionID = revisionID, let siteURL = url else {
            return
        }

        switch source {
        case .diff:
            EditHistoryCompareFunnel.shared.logThankTry(siteURL: siteURL)

        default:
            break
        }

        let logFail = {
            switch self.source {
            case .diff:
                EditHistoryCompareFunnel.shared.logThankFail(siteURL: siteURL)
            default:
                break
            }
        }

        guard !wereThanksSent(for: revisionID) else {

            logFail()

            self.showAuthorAlreadyThankedHint()
            return
        }

        guard !isUserAnonymous else {

            logFail()

            self.showAnonymousUsersCannotBeThankedHint()
            return
        }

        guard isPermanent else {
            let tapLoginHandler: (() -> Void)?
            let category: EventCategoryMEP?
            switch source {
            case .diff:
                tapLoginHandler = {
                    WatchlistFunnel.shared.logDiffThanksLogin(project: WikimediaProject(siteURL: siteURL))
                    LoginFunnel.shared.logLoginStartFromDiff()
                }
                category = .diff
            case .unknown:
                tapLoginHandler = nil
                category = nil
            }
            let alert = UIAlertController(
                title: WMFLocalizedString("diff-thanks-login-title", value: "Log in to send 'Thanks'", comment: "Title for thanks login panel."),
                message: WMFLocalizedString("diff-thanks-login-subtitle", value: "'Thanks' are an easy way to show appreciation for an editor's work on Wikipedia. You must be logged in to send 'Thanks'.", comment: "Subtitle for thanks login panel."),
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: CommonStrings.loginOrCreateAccountTitle, style: .default) { [weak self] _ in
                guard let self else { return }
                tapLoginHandler?()
                self.wmf_showLoginViewController(category: category, theme: self.theme, loginSuccessCompletion: {
                    self.didLogIn()
                }, loginDismissedCompletion: nil)
            })
            alert.addAction(UIAlertAction(title: CommonStrings.cancelActionTitle, style: .cancel))
            present(alert, animated: true)
            return
        }

        let thankCompletion: (Error?) -> Void = { (error) in
            if error == nil {
                self.thanksWereSent(for: revisionID)

                switch self.source {
                case .diff:
                    EditHistoryCompareFunnel.shared.logThankSuccess(siteURL: siteURL)
                    WatchlistFunnel.shared.logDiffThanksDisplaySuccessToast(project: WikimediaProject(siteURL: siteURL))
                default:
                    break
                }

            } else {
                logFail()
            }
        }

        guard !UserDefaults.standard.wmf_didShowThankRevisionAuthorEducationPanel() else {
            thankRevisionAuthor(for: revisionID, completion: thankCompletion)
            return
        }

        wmf_showThankRevisionAuthorEducationPanel(theme: theme) {
            if case .diff = self.source {
                WatchlistFunnel.shared.logDiffThanksAlertTapSend(project: WikimediaProject(siteURL: siteURL))
            }

            UserDefaults.standard.wmf_setDidShowThankRevisionAuthorEducationPanel(true)
            self.thankRevisionAuthor(for: revisionID, completion: thankCompletion)

        } cancelHandler: {

            if case .diff = self.source {
                WatchlistFunnel.shared.logDiffThanksAlertTapCancel(project: WikimediaProject(siteURL: siteURL))
            }
        }
    }

    private func showAuthorAlreadyThankedHint() {
        let title = WMFLocalizedString("diff-thanks-sent-already",
                                      value: "You've already sent a 'Thanks' for this edit",
                                      comment: "Message indicating thanks was already sent")
        let subtitle = WMFLocalizedString("diff-thanks-sent-cannot-unsend",
                                         value: "Thanks cannot be unsent",
                                         comment: "Message indicating thanks cannot be unsent")

        Task { @MainActor in
            WMFToastManager.sharedInstance.showRichToast(
                title,
                subtitle: subtitle,
                image: WMFSFSymbolIcon.for(symbol: .exclamationMarkTriangleFill),
                dismissPreviousToasts: true
            )
        }
    }

    private func showAnonymousUsersCannotBeThankedHint() {
        let message = WMFLocalizedString("diff-thanks-anonymous-no-thanks",
                                        value: "Anonymous users cannot be thanked",
                                        comment: "Message indicating anonymous users cannot be thanked")

        Task { @MainActor in
            WMFToastManager.sharedInstance.showRichToast(
                message,
                subtitle: nil,
                image: WMFSFSymbolIcon.for(symbol: .exclamationMarkTriangleFill),
                dismissPreviousToasts: true
            )
        }
    }

    private func showRevisionAuthorThankedHint(recipient: String) {
        let message = String.localizedStringWithFormat(CommonStrings.thanksMessage, recipient)

        Task { @MainActor in
            WMFToastManager.sharedInstance.showRichToast(
                message,
                subtitle: nil,
                image: WMFSFSymbolIcon.for(symbol: .checkmarkCircleFill),
                dismissPreviousToasts: true
            )
        }
    }

    private func showRevisionAuthorThanksErrorHint(error: Error) {
        let message = (error as NSError).alertMessage()

        Task { @MainActor in
            WMFToastManager.sharedInstance.showRichToast(
                message,
                subtitle: nil,
                image: WMFSFSymbolIcon.for(symbol: .exclamationMarkTriangleFill),
                dismissPreviousToasts: true
            )
        }
    }

    private func thankRevisionAuthor(for revisionID: Int, completion: @escaping ((Error?) -> Void)) {
        self.thankRevisionAuthor(toRevisionId: revisionID) { [weak self] (result) in
            guard let self = self else {
                return
            }
            DispatchQueue.main.async {
                switch result {
                case .success(let result):
                    if UIAccessibility.isVoiceOverRunning {
                        let accessibilityText = String.localizedStringWithFormat(CommonStrings.thanksMessage, result.recipient)
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            UIAccessibility.post(notification: UIAccessibility.Notification.announcement, argument: accessibilityText)
                        }
                    } else {
                        self.showRevisionAuthorThankedHint(recipient: result.recipient)
                    }
                    completion(nil)
                case .failure(let error as NSError):
                    if UIAccessibility.isVoiceOverRunning {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            UIAccessibility.post(notification: UIAccessibility.Notification.announcement, argument: error.alertMessage())
                        }
                    } else {
                        self.showRevisionAuthorThanksErrorHint(error: error)
                    }
                    completion(error)
                }
            }
        }
    }

    private func thankRevisionAuthor(toRevisionId: Int, completion: @escaping ((Result<DiffThankerResult, Error>) -> Void)) {
        guard let siteURL = url else {
            return
        }
        let diffThanker = DiffThanker()
        diffThanker.thank(siteURL: siteURL, rev: toRevisionId, completion: completion)
    }
}
