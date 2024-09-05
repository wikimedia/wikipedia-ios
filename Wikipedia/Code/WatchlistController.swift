import Foundation
import WMF
import WMFData

protocol WatchlistControllerDelegate: AnyObject {
    func didSuccessfullyWatchTemporarily(_ controller: WatchlistController)
    func didSuccessfullyWatchPermanently(_ controller: WatchlistController)
    func didSuccessfullyUnwatch(_ controller: WatchlistController)
}

/// This controller contains reusable logic for watching, updating expiry, and unwatching a page. It triggers the network service calls, as well as displays the appropriate toasts and action sheets based on the response.
class WatchlistController {
    
    enum Context {
        case diff
        case article
    }
    
    private let dataController = WMFWatchlistDataController()
    let context: Context
    private weak var delegate: WatchlistControllerDelegate?
    private weak var lastPopoverPresentationController: UIPopoverPresentationController?
    private var performAfterLoginBlock: (() -> Void)?
    private let toastCustomTypeName = "watchlist-add-remove-success"
    
    init(delegate: WatchlistControllerDelegate, context: Context) {
        self.delegate = delegate
        self.context = context
        NotificationCenter.default.addObserver(self, selector: #selector(didLogIn), name:WMFAuthenticationManager.didLogInNotification, object: nil)
    }
    
    @objc private func didLogIn() {
        
        // Delay a little bit to allow login view controller dismissal to complete
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.performAfterLoginBlock?()
            self?.performAfterLoginBlock = nil
        }
        
    }
    
    func watch(pageTitle: String, siteURL: URL, expiry: WMFWatchlistExpiryType = .never, viewController: UIViewController, authenticationManager: WMFAuthenticationManager, theme: Theme, sender: UIBarButtonItem, sourceView: UIView?, sourceRect: CGRect?) {
        
        guard authenticationManager.authStateIsPermanent else {
            performAfterLoginBlock = { [weak self] in
                self?.watch(pageTitle: pageTitle, siteURL: siteURL, viewController: viewController, authenticationManager: authenticationManager, theme: theme, sender: sender, sourceView: sourceView, sourceRect: sourceRect)
            }
            viewController.wmf_showLoginViewController(theme: theme)
            return
        }
        
        guard let wikimediaProject = WikimediaProject(siteURL: siteURL),
        let wmfProject = wikimediaProject.wmfProject else {
            viewController.showGenericError()
            return
        }
        
        switch context {
        case .article:
            WatchlistFunnel.shared.logAddToWatchlist(project: wikimediaProject)
        case .diff:
            WatchlistFunnel.shared.logAddToWatchlistFromDiff(project: wikimediaProject)
        }
        
        presentChooseExpiryActionSheet(pageTitle: pageTitle, siteURL: siteURL, wmfProject: wmfProject, viewController: viewController, theme: theme, sender: sender, sourceView: sourceView, sourceRect: sourceRect, authenticationManager: authenticationManager)
    }
    
    private func displayWatchSuccessMessage(pageTitle: String, wmfProject: WMFProject, siteURL: URL, expiry: WMFWatchlistExpiryType, viewController: UIViewController, theme: Theme, sender: UIBarButtonItem, sourceView: UIView?, sourceRect: CGRect?) {
        let statusTitle: String
        let image = expiry == .never ? UIImage(systemName: "star.fill") : UIImage(systemName: "star.leadinghalf.filled")
        switch expiry {
        case .never:
            statusTitle = WMFLocalizedString("watchlist-added-toast-permanently", value: "Added to your Watchlist permanently.", comment: "Title in toast after a user successfully adds an article to their watchlist, with no expiration.")
        case .oneWeek:
            statusTitle = WMFLocalizedString("watchlist-added-toast-one-week", value: "Added to your Watchlist for 1 week.", comment: "Title in toast after a user successfully adds an article to their watchlist, which expires in one week.")
        case .oneMonth:
            statusTitle = WMFLocalizedString("watchlist-added-toast-one-month", value: "Added to your Watchlist for 1 month.", comment: "Title in toast after a user successfully adds an article to their watchlist, which expires in one month.")
        case .threeMonths:
            statusTitle = WMFLocalizedString("watchlist-added-toast-three-months", value: "Added to your Watchlist for 3 months.", comment: "Title in toast after a user successfully adds an article to their watchlist, which expires in three months.")
        case .sixMonths:
            statusTitle = WMFLocalizedString("watchlist-added-toast-six-months", value: "Added to your Watchlist for 6 months.", comment: "Title in toast after a user successfully adds an article to their watchlist, which expires in 6 months.")
        case .oneYear:
            statusTitle = WMFLocalizedString("watchlist-added-toast-one-year", value: "Added to your Watchlist for 1 year.", comment: "Title in toast after a user successfully adds an article to their watchlist, which expires in 1 year.")
        }
        
        let promptTitle = WMFLocalizedString("watchlist-added-toast-view-watchlist", value: "View Watchlist", comment: "Button in toast after a user successfully adds an article to their watchlist. Tapping will take them to their watchlist.")
        
        let wikimediaProject = WikimediaProject(wmfProject: wmfProject)
        
        switch context {
        case .article:
            WatchlistFunnel.shared.logAddToWatchlistDisplaySuccessToast(project: wikimediaProject)
        case .diff:
            WatchlistFunnel.shared.logAddToWatchlistDisplaySuccessToastFromDiff(project: wikimediaProject)
        }
        
        let context = self.context
        let navigateToWatchlistBlock: (() -> Void) = {
            
            switch context {
            case .article:
                WatchlistFunnel.shared.logOpenWatchlistFromArticleAddedToast(project: wikimediaProject)
            case .diff:
                WatchlistFunnel.shared.logOpenWatchlistFromDiffAddedToast(project: wikimediaProject)
            }
            
            guard let linkURL = siteURL.wmf_URL(withTitle: "Special:Watchlist"),
            let userActivity = NSUserActivity.wmf_activity(for: linkURL) else {
                return
            }
            
            NSUserActivity.wmf_navigate(to: userActivity)
        }
        
        let duration: TimeInterval? = UIAccessibility.isVoiceOverRunning ? 10 : 5
        
        WMFAlertManager.sharedInstance.showBottomAlertWithMessage(statusTitle, subtitle: nil, image: image, type: .custom, customTypeName: toastCustomTypeName, duration: duration, dismissPreviousAlerts: true, callback: navigateToWatchlistBlock, buttonTitle: promptTitle, buttonCallBack: navigateToWatchlistBlock)
        
        if UIAccessibility.isVoiceOverRunning {
            DispatchQueue.main.async {
                UIAccessibility.post(notification: .layoutChanged, argument: [statusTitle, WMFAlertManager.sharedInstance.topMessageView()] as [Any])
            }
        }
    }
    
    private func presentChooseExpiryActionSheet(pageTitle: String, siteURL: URL, wmfProject: WMFProject, viewController: UIViewController, theme: Theme, sender: UIBarButtonItem, sourceView: UIView?, sourceRect: CGRect?, authenticationManager: WMFAuthenticationManager) {
        
        WMFAlertManager.sharedInstance.dismissAllAlerts()
        
        let title = WMFLocalizedString("watchlist-change-expiry-title", value: "Watchlist expiry", comment: "Title of modal that allows a user to change the expiry setting of a page they are watching.")
        let message = WMFLocalizedString("watchlist-change-expiry-subtitle", value: "Choose Watchlist time period", comment: "Subtitle in modal that allows a user to choose the expiry setting of a page they are watching.")
        
        let expiryOptionPermanent = WMFLocalizedString("watchlist-change-expiry-option-permanent", value: "Permanent", comment: "Title of button in expiry change modal that permanently watches a page.")
        
        let expiryOptionOneWeek = WMFLocalizedString("watchlist-change-expiry-option-one-week", value: "1 week", comment: "Title of button in expiry change modal that watches a page for one week.")
        
        let expiryOptionOneMonth = WMFLocalizedString("watchlist-change-expiry-option-one-month", value: "1 month", comment: "Title of button in expiry change modal that watches a page for one month.")
        
        let expiryOptionThreeMonths = WMFLocalizedString("watchlist-change-expiry-option-three-months", value: "3 months", comment: "Title of button in expiry change modal that watches a page for three months.")
        
        let expiryOptionSixMonths = WMFLocalizedString("watchlist-change-expiry-option-six-months", value: "6 months", comment: "Title of button in expiry change modal that watches a page for six months.")
        
        let expiryOptionOneYear = WMFLocalizedString("watchlist-change-expiry-option-one-year", value: "1 year", comment: "Title of button in expiry change modal that watches a page for one year.")
        
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .actionSheet)
        
        let titles = [expiryOptionPermanent, expiryOptionOneWeek, expiryOptionOneMonth, expiryOptionThreeMonths, expiryOptionSixMonths, expiryOptionOneYear]
        let expirys: [WMFWatchlistExpiryType] = [.never, .oneWeek, .oneMonth, .threeMonths, .sixMonths, .oneYear]
        
        let wikimediaProject = WikimediaProject(wmfProject: wmfProject)
        for (title, expiry) in zip(titles, expirys) {
            
            let action = UIAlertAction(title: title, style: .default) { [weak self] (action) in
                
                switch expiry {
                case .never:
                    WatchlistFunnel.shared.logExpiryTapPermanent(project: wikimediaProject)
                case .oneWeek:
                    WatchlistFunnel.shared.logExpiryTapOneWeek(project: wikimediaProject)
                case .oneMonth:
                    WatchlistFunnel.shared.logExpiryTapOneMonth(project: wikimediaProject)
                case .threeMonths:
                    WatchlistFunnel.shared.logExpiryTapThreeMonths(project: wikimediaProject)
                case .sixMonths:
                    WatchlistFunnel.shared.logExpiryTapSixMonths(project: wikimediaProject)
                case .oneYear:
                    WatchlistFunnel.shared.logExpiryTapOneYear(project: wikimediaProject)
                }
                
                self?.dataController.watch(title: pageTitle, project: wmfProject, expiry: expiry, completion: { [weak self] result in
                    
                    DispatchQueue.main.async {
                        guard let self else {
                            return
                        }
                        
                        switch result {
                        case .success:
                            if expiry == .never {
                                self.delegate?.didSuccessfullyWatchPermanently(self)
                            } else {
                                self.delegate?.didSuccessfullyWatchTemporarily(self)
                            }
                            self.displayWatchSuccessMessage(pageTitle: pageTitle, wmfProject: wmfProject, siteURL: siteURL, expiry: expiry, viewController: viewController, theme: theme, sender: sender, sourceView: sourceView, sourceRect: sourceRect)
                        case .failure(let error):
                            self.evaluateServerError(error: error, viewController: viewController, theme: theme, performAfterLoginBlock: { [weak self] in
                                self?.watch(pageTitle: pageTitle, siteURL: siteURL, viewController: viewController, authenticationManager: authenticationManager, theme: theme, sender: sender, sourceView: sourceView, sourceRect: sourceRect)
                            })
                        }
                    }
                    
                })
            }
            
            alertController.addAction(action)
            
        }
        
        let cancelAction = UIAlertAction(title: CommonStrings.cancelActionTitle, style: .cancel, handler: {_ in 
            WatchlistFunnel.shared.logExpiryCancel(project: wikimediaProject)
        })
        
        alertController.addAction(cancelAction)
        
        if let popoverController = alertController.popoverPresentationController {
            lastPopoverPresentationController = popoverController
            calculatePopoverPosition(sender: sender, sourceView: sourceView, sourceRect: sourceRect)
        }
        
        alertController.overrideUserInterfaceStyle = theme.isDark ? .dark : .light
        
        switch context {
        case .article:
            WatchlistFunnel.shared.logPresentExpiryChoiceActionSheet(project: wikimediaProject)
        case .diff:
            WatchlistFunnel.shared.logPresentExpiryChoiceActionSheetFromDiff(project: wikimediaProject)
        }
        
        viewController.present(alertController, animated: true)
    }
    
    func unwatch(pageTitle: String, siteURL: URL, viewController: UIViewController, authenticationManager: WMFAuthenticationManager, theme: Theme) {
        
        guard authenticationManager.authStateIsPermanent else {
            performAfterLoginBlock = { [weak self] in
                self?.unwatch(pageTitle: pageTitle, siteURL: siteURL, viewController: viewController, authenticationManager: authenticationManager, theme: theme)
            }
            viewController.wmf_showLoginViewController(theme: theme)
            return
        }
        
        guard let wikimediaProject = WikimediaProject(siteURL: siteURL),
              let wmfProject = wikimediaProject.wmfProject else {
            viewController.showGenericError()
            return
        }
        
        switch context {
        case .article:
            WatchlistFunnel.shared.logRemoveWatchlistItem(project: wikimediaProject)
        case .diff:
            WatchlistFunnel.shared.logRemoveWatchlistItemFromDiff(project: wikimediaProject)
        }
        
        dataController.unwatch(title: pageTitle, project: wmfProject) { [weak self] result in
            
            DispatchQueue.main.async {
                
                guard let self else {
                    return
                }
                
                switch result {
                case .success:
                    
                    switch self.context {
                    case .article:
                        WatchlistFunnel.shared.logRemoveWatchlistItemDisplaySuccessToast(project: wikimediaProject)
                    case .diff:
                        WatchlistFunnel.shared.logRemoveWatchlistItemDisplaySuccessToastFromDiff(project: wikimediaProject)
                    }
                    
                    let title = WMFLocalizedString("watchlist-removed", value: "Removed from your Watchlist", comment: "Title in toast after a user successfully removes an article from their watchlist.")
                    let image = UIImage(systemName: "star")
                    
                    if !UIAccessibility.isVoiceOverRunning {
                        WMFAlertManager.sharedInstance.showBottomAlertWithMessage(title, subtitle: nil, image: image, type: .custom, customTypeName: self.toastCustomTypeName, dismissPreviousAlerts: true)
                    } else {
                        UIAccessibility.post(notification: .layoutChanged, argument: [title] as [Any])
                    }
                    
                    self.delegate?.didSuccessfullyUnwatch(self)
                case .failure(let error):
                    self.evaluateServerError(error: error, viewController: viewController, theme: theme, performAfterLoginBlock: { [weak self] in
                        self?.unwatch(pageTitle: pageTitle, siteURL: siteURL, viewController: viewController, authenticationManager: authenticationManager, theme: theme)
                    })
                }
            }
        }
    }
    
    private func evaluateServerError(error: Error, viewController: UIViewController, theme: Theme, performAfterLoginBlock: @escaping () -> Void) {
        
        let fallback: (Error) -> Void = { error in
            if UIAccessibility.isVoiceOverRunning {
                UIAccessibility.post(notification: .layoutChanged, argument: [(error as NSError).alertMessage()] as [Any])
            } else {
                WMFAlertManager.sharedInstance.showErrorAlert(error, sticky: false, dismissPreviousAlerts: true)
            }
        }
        
        guard let dataControllerError = error as? WMFData.WMFDataControllerError else {
            fallback(error)
            return
        }
        
        switch dataControllerError {
        case .serviceError(let error):

            guard let mediaWikiError = error as? MediaWikiFetcher.MediaWikiFetcherError else {
                fallback(error)
                return
            }
            
            switch mediaWikiError {
            case .mediaWikiAPIResponseError(let displayError):
                guard displayError.code == "notloggedin" else {
                    fallback(error)
                    return
                }
                
                self.performAfterLoginBlock = performAfterLoginBlock
                viewController.wmf_showLoginViewController(theme: theme)
                return
            default:
                break
            }
                
        default:
            break
        }
        
        fallback(error)
    }
    
    func calculatePopoverPosition(sender: UIBarButtonItem, sourceView: UIView?, sourceRect: CGRect?) {
        guard let lastPopoverPresentationController else {
            return
        }
        
        if let sourceView = sourceView,
           let sourceRect = sourceRect {
            lastPopoverPresentationController.sourceView = sourceView
            lastPopoverPresentationController.sourceRect = sourceRect
        } else {
            lastPopoverPresentationController.barButtonItem = sender
        }
    }
    
    static func calculateToolbarFifthButtonSourceRect(toolbarView: UIView, thirdButtonView: UIView, fourthButtonView: UIView) -> CGRect {
        
        let thirdButtonFrame = toolbarView.convert(thirdButtonView.frame, from: thirdButtonView.superview)
        let fourthButtonFrame = toolbarView.convert(fourthButtonView.frame, from: fourthButtonView.superview)
        
        let spacing = fourthButtonFrame.maxX - thirdButtonFrame.maxX
        
        let fifthFrame = CGRect(x: fourthButtonFrame.minX + spacing + 5, y: fourthButtonFrame.minY - 5, width: fourthButtonFrame.width, height: fourthButtonFrame.height)
        return fifthFrame
    }
}
