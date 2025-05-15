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
        
        Task { [weak self] in
            guard let self else { return }
            var previousArticleTab: WMFArticleTabsDataController.WMFArticle?
            var nextArticleTab: WMFArticleTabsDataController.WMFArticle?
            if let tabDataController = WMFArticleTabsDataController.shared,
               let tabIdentifier = self.coordinator?.tabIdentifier {
                previousArticleTab = try? await tabDataController.getAdjacentArticleInTab(tabIdentifier: tabIdentifier, isPrev: true)
                nextArticleTab = try? await tabDataController.getAdjacentArticleInTab(tabIdentifier: tabIdentifier, isPrev: false)
            }
            
            Task { @MainActor in
                self.toolbarController.updateMoreButton(needsWatchButton: false, needsUnwatchHalfButton: true, needsUnwatchFullButton: false, previousArticleTab: previousArticleTab, nextArticleTab: nextArticleTab)
            }
        }
        
        
    }
    
    func didSuccessfullyWatchPermanently(_ controller: WatchlistController) {
        
        Task { [weak self] in
            guard let self else { return }
            var previousArticleTab: WMFArticleTabsDataController.WMFArticle?
            var nextArticleTab: WMFArticleTabsDataController.WMFArticle?
            if let tabDataController = WMFArticleTabsDataController.shared,
               let tabIdentifier = self.coordinator?.tabIdentifier {
                previousArticleTab = try? await tabDataController.getAdjacentArticleInTab(tabIdentifier: tabIdentifier, isPrev: true)
                nextArticleTab = try? await tabDataController.getAdjacentArticleInTab(tabIdentifier: tabIdentifier, isPrev: false)
            }
            
            Task { @MainActor in
                self.toolbarController.updateMoreButton(needsWatchButton: false, needsUnwatchHalfButton: false, needsUnwatchFullButton: true, previousArticleTab: previousArticleTab, nextArticleTab: nextArticleTab)
            }
        }
        
        
    }
    
    func didSuccessfullyUnwatch(_ controller: WatchlistController) {
        
        Task { [weak self] in
            guard let self else { return }
            var previousArticleTab: WMFArticleTabsDataController.WMFArticle?
            var nextArticleTab: WMFArticleTabsDataController.WMFArticle?
            if let tabDataController = WMFArticleTabsDataController.shared,
               let tabIdentifier = self.coordinator?.tabIdentifier {
                previousArticleTab = try? await tabDataController.getAdjacentArticleInTab(tabIdentifier: tabIdentifier, isPrev: true)
                nextArticleTab = try? await tabDataController.getAdjacentArticleInTab(tabIdentifier: tabIdentifier, isPrev: false)
            }
            
            Task { @MainActor in
                self.toolbarController.updateMoreButton(needsWatchButton: true, needsUnwatchHalfButton: false, needsUnwatchFullButton: false, previousArticleTab: previousArticleTab, nextArticleTab: nextArticleTab)
            }
        }
        
    }
}
