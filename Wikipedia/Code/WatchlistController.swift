import Foundation
import WMF
import WKData

protocol WatchlistControllerDelegate: AnyObject {
    func didSuccessfullyWatch(_ controller: WatchlistController)
    func didSuccessfullyUnwatch(_ controller: WatchlistController)
}

class WatchlistController {
    
    private let service = WKWatchlistService()
    private weak var delegate: WatchlistControllerDelegate?
    
    init(delegate: WatchlistControllerDelegate) {
        self.delegate = delegate
    }
    
    func watch(pageTitle: String, siteURL: URL, expiry: WKWatchlistExpiryType = .never, viewController: UIViewController, authenticationManager: WMFAuthenticationManager, theme: Theme) {
        
        guard authenticationManager.isLoggedIn else {
            viewController.wmf_showLoginViewController(theme: theme)
            return
        }
        
        guard let wkProject = WikimediaProject(siteURL: siteURL)?.wkProject else {
            viewController.showGenericError()
            return
        }
        
        service.watch(title: pageTitle, project: wkProject, expiry: expiry) { [weak self] result in
            DispatchQueue.main.async {
                guard let self else {
                    return
                }
                
                switch result {
                case .success:
                    self.displayWatchSuccessMessageWithExpiry(expiry)
                    self.delegate?.didSuccessfullyWatch(self)
                case .failure(let error):
                    WMFAlertManager.sharedInstance.showErrorAlert(error, sticky: false, dismissPreviousAlerts: true)
                }
            }
        }
    }
    
    private func displayWatchSuccessMessageWithExpiry(_ expiry: WKWatchlistExpiryType) {
        let statusTitle: String
        let image = UIImage(systemName: "star.fill")
        switch expiry {
        case .never:
            statusTitle = WMFLocalizedString("watchlist-added-toast-permanently", value: "Added to Watchlist permanently", comment: "Title in toast after a user successfully adds an article to their watchlist, with no expiration.")
        case .oneWeek:
            statusTitle = WMFLocalizedString("watchlist-added-toast-one-week", value: "Added to Watchlist for 1 week", comment: "Title in toast after a user successfully adds an article to their watchlist, which expires in one week.")
        case .oneMonth:
            statusTitle = WMFLocalizedString("watchlist-added-toast-one-month", value: "Added to Watchlist for 1 month", comment: "Title in toast after a user successfully adds an article to their watchlist, which expires in one month.")
        case .threeMonths:
            statusTitle = WMFLocalizedString("watchlist-added-toast-three-months", value: "Added to Watchlist for 3 months", comment: "Title in toast after a user successfully adds an article to their watchlist, which expires in three months.")
        case .sixMonths:
            statusTitle = WMFLocalizedString("watchlist-added-toast-six-months", value: "Added to Watchlist for 6 months", comment: "Title in toast after a user successfully adds an article to their watchlist, which expires in 6 months.")
        }
        
        let promptTitle = WMFLocalizedString("watchlist-added-toast-change-expiration", value: "Change expiration date?", comment: "Title in toast after a user successfully adds an article to their watchlist. Tapping will allow them to change their watchlist item expiration date.")
        
        WMFAlertManager.sharedInstance.showBottomAlertWithMessage("\(statusTitle)\n\(promptTitle)", subtitle: nil, image: image, type: .custom, customTypeName: "subscription-success", dismissPreviousAlerts: true)
    }
    
    func unwatch(pageTitle: String, siteURL: URL, viewController: UIViewController, authenticationManager: WMFAuthenticationManager, theme: Theme) {
        
        guard authenticationManager.isLoggedIn else {
            viewController.wmf_showLoginViewController(theme: theme)
            return
        }
        
        guard let wkProject = WikimediaProject(siteURL: siteURL)?.wkProject else {
            viewController.showGenericError()
            return
        }
        
        service.unwatch(title: pageTitle, project: wkProject) { [weak self] result in
            
            DispatchQueue.main.async {
                
                guard let self else {
                    return
                }
                
                switch result {
                case .success:
                    let title = WMFLocalizedString("watchlist-removed", value: "Removed from your watchlist", comment: "Title in toast after a user successfully removes an article from their watchlist.")
                    let image = UIImage(systemName: "star")
                    WMFAlertManager.sharedInstance.showBottomAlertWithMessage(title, subtitle: nil, image: image, type: .custom, customTypeName: "subscription-success", dismissPreviousAlerts: true)
                    self.delegate?.didSuccessfullyUnwatch(self)
                case .failure(let error):
                    WMFAlertManager.sharedInstance.showErrorAlert(error, sticky: false, dismissPreviousAlerts: true)
                }
            }
        }
    }
}
