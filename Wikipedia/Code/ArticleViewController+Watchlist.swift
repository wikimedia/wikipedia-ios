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
        
        WMFAlertManager().showAlert("Saving!", sticky: false, dismissPreviousAlerts: true)
        
        guard let username = dataStore.authenticationManager.loggedInUsername,
        let articleTitle = articleURL.wmf_title,
        let languageCode = articleURL.wmf_languageCode else {
            return
        }

        let articleWikiLanguage = WKLanguage(languageCode: languageCode, languageVariantCode: nil)
        let testWikiLanguage = WKLanguage(languageCode: "test", languageVariantCode: nil)
        let sandboxDataController = WKSandboxDataController()
        sandboxDataController.getWikitext(project: WKProject.wikipedia(articleWikiLanguage), title: articleTitle) { result in
            switch result {
            case .success(let wikitext):

                sandboxDataController.saveWikitextToSandbox(project: WKProject.wikipedia(testWikiLanguage), username: username, sandboxTitle: articleTitle, wikitext: wikitext) { [weak self] result in
                    switch result {
                    case .success:
                        let sandboxVC = WKSandboxViewController(username: username)
                        self?.navigationController?.pushViewController(sandboxVC, animated: true)
                    case .failure(let error):
                        WMFAlertManager().showAlert("Failure!", sticky: false, dismissPreviousAlerts: true)
                    }
                }

            case .failure(let error):
                WMFAlertManager().showAlert("Failure!", sticky: false, dismissPreviousAlerts: true)
            }
        }

    }
}
