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
    }
    
    func unwatch() {
    }
}
