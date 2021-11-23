import Foundation

protocol ThanksGiving: HintPresenting {
    var url: URL? { get }
    var hintController: HintController? { get set }
    var bottomSpacing: CGFloat? { get }
    func didLogIn()
    func wereThanksSent(for revisionID: Int) -> Bool
    func thanksWereSent(for revisionID: Int)
}

enum ThanksGivingSource {
    case diff
    case articleAsLivingDoc
    case unknown
}

struct ArticleAsLivingDocLoggingValues {
    let position: Int
    let eventTypes: [ArticleAsLivingDocFunnel.EventType]
}

extension ThanksGiving where Self: ViewController {

    var source: ThanksGivingSource {
        
        switch self {
        case is ArticleAsLivingDocViewController:
            return .articleAsLivingDoc
        case is DiffContainerViewController:
            return .diff
        default:
            return .unknown
        }
    }

    var isLoggedIn: Bool {
        // SINGLETONTODO
        return MWKDataStore.shared().authenticationManager.isLoggedIn
    }

    func tappedThank(for revisionID: Int?, isUserAnonymous: Bool, livingDocLoggingValues: ArticleAsLivingDocLoggingValues? = nil) {
        guard let revisionID = revisionID, let siteURL = url else {
            return
        }
        
        switch source {
        case .diff:
            EditHistoryCompareFunnel.shared.logThankTry(siteURL: siteURL)
        case .articleAsLivingDoc:
            if let livingDocLoggingValues = livingDocLoggingValues {
                ArticleAsLivingDocFunnel.shared.logModalThankTryButtonTapped(position: livingDocLoggingValues.position, types: livingDocLoggingValues.eventTypes)
            }
        default:
            break
        }
        
        let logFail = {
            switch self.source {
            case .diff:
                EditHistoryCompareFunnel.shared.logThankFail(siteURL: siteURL)
            case .articleAsLivingDoc:
                if let livingDocLoggingValues = livingDocLoggingValues {
                    ArticleAsLivingDocFunnel.shared.logModalThankFail(position: livingDocLoggingValues.position, types: livingDocLoggingValues.eventTypes)
                }
            default:
                break
            }
        }

        guard !wereThanksSent(for: revisionID) else {
    
            logFail()
            
            self.show(hintViewController: AuthorAlreadyThankedHintVC())
            return
        }

        guard !isUserAnonymous else {
            
            logFail()
            
            self.show(hintViewController: AnonymousUsersCannotBeThankedHintVC())
            return
        }

        guard isLoggedIn else {
            wmf_showLoginOrCreateAccountToThankRevisionAuthorPanel(theme: theme, dismissHandler: nil, loginSuccessCompletion: {
                self.didLogIn()
            }, loginDismissedCompletion: nil)
            return
        }

        let thankCompletion: (Error?) -> Void = { (error) in
            if error == nil {
                self.thanksWereSent(for: revisionID)
                
                switch self.source {
                case .diff:
                    EditHistoryCompareFunnel.shared.logThankSuccess(siteURL: siteURL)
                case .articleAsLivingDoc:
                    if let livingDocLoggingValues = livingDocLoggingValues {
                        ArticleAsLivingDocFunnel.shared.logModalThankSuccess(position: livingDocLoggingValues.position, types: livingDocLoggingValues.eventTypes)
                    }
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

        wmf_showThankRevisionAuthorEducationPanel(theme: theme, sendThanksHandler: {_ in
            UserDefaults.standard.wmf_setDidShowThankRevisionAuthorEducationPanel(true)
            self.dismiss(animated: true, completion: {
                self.thankRevisionAuthor(for: revisionID, completion: thankCompletion)
            })
        })
    }

    private func show(hintViewController: HintViewController) {
        let showHint = {
            self.hintController = HintController(hintViewController: hintViewController)
            self.hintController?.toggle(presenter: self, context: nil, theme: self.theme, additionalBottomSpacing: self.bottomSpacing ?? 0)
            self.hintController?.setHintHidden(false)
        }
        if let hintController = self.hintController {
            hintController.setHintHidden(true) {
                showHint()
            }
        } else {
            showHint()
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
                    self.show(hintViewController: RevisionAuthorThankedHintVC(recipient: result.recipient))
                    completion(nil)
                case .failure(let error as NSError):
                    self.show(hintViewController: RevisionAuthorThanksErrorHintVC(error: error))
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
