import Foundation
import WKData
import Components

extension ArticleViewController {
    func loadWatchStatusAndUpdateToolbar() {
        
        guard FeatureFlags.watchlistEnabled,
        let title = articleURL.wmf_title,
        let siteURL = articleURL.wmf_site,
        let project = WikimediaProject(siteURL: siteURL)?.wkProject else {
            return
        }
        
        WKWatchlistDataController().fetchWatchStatus(title: title, project: project) { result in
            
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

extension ArticleViewController {
    func goToSandbox() {

        let cs1 = SandboxViewModel.CategorySandbox(categoryTitle: "Geography", sandboxCount: 354545, followerCount:23498718712)
        let cs2 = SandboxViewModel.CategorySandbox(categoryTitle: "Biology", sandboxCount: 1549, followerCount:3847834297)
        let cs3 = SandboxViewModel.CategorySandbox(categoryTitle: "Art", sandboxCount: 917386274527, followerCount:673726382)

        guard let username = dataStore.authenticationManager.loggedInUsername else {
            return
        }

        let categorySandboxes = [cs1, cs2, cs3]
        let viewModel = SandboxViewModel(username: username, categorySandboxes: categorySandboxes)
        let sandboxVC = WKSandboxViewController(viewModel: viewModel)
        navigationController?.pushViewController(sandboxVC, animated: true)

    }
}
