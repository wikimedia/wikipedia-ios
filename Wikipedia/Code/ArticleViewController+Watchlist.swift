import Foundation
import WMFData

extension ArticleViewController {
    
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
