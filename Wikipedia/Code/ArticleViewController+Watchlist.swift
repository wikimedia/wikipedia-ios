import Foundation
import WMFData

extension ArticleViewController {
    func loadWatchStatusAndUpdateToolbar() {
        
        guard let title = articleURL.wmf_title,
        let siteURL = articleURL.wmf_site,
        let project = WikimediaProject(siteURL: siteURL)?.wmfProject else {
            return
        }
        
        WMFWatchlistDataController().fetchWatchStatus(title: title, project: project) { result in
            
            DispatchQueue.main.async { [weak self] in
                
                guard let self else {
                    return
                }
                
                switch result {
                case .success(let status):
                    
                    let needsWatchButton = !status.watched
                    let needsUnwatchHalfButton = status.watched && status.watchlistExpiry != nil
                    let needsUnwatchFullButton = status.watched && status.watchlistExpiry == nil
                    
                    self.toolbarController.updateMoreButton(needsWatchButton: needsWatchButton, needsUnwatchHalfButton: needsUnwatchHalfButton, needsUnwatchFullButton: needsUnwatchFullButton)
                case .failure:
                    break
                }
            }
        }
    }
    
    func watch() {
        
        guard let title = articleURL.wmf_title,
        let siteURL = articleURL.wmf_site else {
            showGenericError()
            return
        }
        
        watchlistController.watch(pageTitle: title, siteURL: siteURL, viewController: self, authenticationManager: authManager, theme: theme, sender: toolbarController.moreButton, sourceView: toolbarController.moreButtonSourceView, sourceRect: toolbarController.moreButtonSourceRect)
    }
    
    func unwatch() {
        
        guard let title = articleURL.wmf_title,
        let siteURL = articleURL.wmf_site else {
            showGenericError()
            return
        }
        
        watchlistController.unwatch(pageTitle: title, siteURL: siteURL, viewController: self, authenticationManager: authManager, theme: theme)
    }
}

extension ArticleViewController: WatchlistControllerDelegate {
    func didSuccessfullyWatchTemporarily(_ controller: WatchlistController) {
        toolbarController.updateMoreButton(needsWatchButton: false, needsUnwatchHalfButton: true, needsUnwatchFullButton: false)
    }
    
    func didSuccessfullyWatchPermanently(_ controller: WatchlistController) {
        toolbarController.updateMoreButton(needsWatchButton: false, needsUnwatchHalfButton: false, needsUnwatchFullButton: true)
    }
    
    func didSuccessfullyUnwatch(_ controller: WatchlistController) {
        toolbarController.updateMoreButton(needsWatchButton: true, needsUnwatchHalfButton: false, needsUnwatchFullButton: false)
    }
}
