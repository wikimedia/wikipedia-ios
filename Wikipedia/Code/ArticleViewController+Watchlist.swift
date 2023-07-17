import Foundation
import WKData

extension ArticleViewController {
    func loadWatchStatusAndUpdateToolbar() {
        
        guard FeatureFlags.watchlistEnabled,
        let title = articleURL.wmf_title,
        let siteURL = articleURL.wmf_site,
        let project = WikimediaProject(siteURL: siteURL)?.wkProject else {
            return
        }
        
        WKWatchlistService().fetchWatchStatus(title: title, project: project) { result in
            
            DispatchQueue.main.async { [weak self] in
                
                guard let self else {
                    return
                }
                
                switch result {
                case .success(let status):
                    
                    let needsWatchButton = !status.watched
                    let needsUnwatchButton = status.watched
                    
                    self.toolbarController.updateMoreButton(needsWatchButton: needsWatchButton, needsUnwatchButton: needsUnwatchButton)
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
    func didSuccessfullyWatch(_ controller: WatchlistController) {
        toolbarController.updateMoreButton(needsWatchButton: false, needsUnwatchButton: true)
    }
    
    func didSuccessfullyUnwatch(_ controller: WatchlistController) {
        toolbarController.updateMoreButton(needsWatchButton: true, needsUnwatchButton: false)
    }
}
