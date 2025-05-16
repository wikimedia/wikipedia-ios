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
        self.needsWatchButton = false
        self.needsUnwatchHalfButton = true
        self.needsUnwatchFullButton = false
        self.toolbarController.updateMoreButton(needsWatchButton: self.needsWatchButton, needsUnwatchHalfButton: self.needsUnwatchHalfButton, needsUnwatchFullButton: self.needsUnwatchFullButton, previousArticleTab: previousArticleTab, nextArticleTab: nextArticleTab)
        
    }
    
    func didSuccessfullyWatchPermanently(_ controller: WatchlistController) {
        
        self.needsWatchButton = false
        self.needsUnwatchHalfButton = false
        self.needsUnwatchFullButton = true
        
        self.toolbarController.updateMoreButton(needsWatchButton: self.needsWatchButton, needsUnwatchHalfButton: self.needsUnwatchHalfButton, needsUnwatchFullButton: self.needsUnwatchFullButton, previousArticleTab: previousArticleTab, nextArticleTab: nextArticleTab)
        
        
    }
    
    func didSuccessfullyUnwatch(_ controller: WatchlistController) {
        
        self.needsWatchButton = true
        self.needsUnwatchHalfButton = false
        self.needsUnwatchFullButton = false
        
        self.toolbarController.updateMoreButton(needsWatchButton: self.needsWatchButton, needsUnwatchHalfButton: self.needsUnwatchHalfButton, needsUnwatchFullButton: self.needsUnwatchFullButton, previousArticleTab: previousArticleTab, nextArticleTab: nextArticleTab)
    }
}
