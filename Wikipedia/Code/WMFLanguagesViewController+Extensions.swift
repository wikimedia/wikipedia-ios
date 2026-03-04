import Foundation
import WMFComponents

extension WMFLanguagesViewController: WMFNavigationBarConfiguring {
    
    @objc func configureNavigationBarFromObjC(title: String) {
        let titleConfig: WMFNavigationBarTitleConfig = WMFNavigationBarTitleConfig(title: title, customView: nil, alignment: .centerCompact)
        let closeButtonConfig = WMFLargeCloseButtonConfig(imageType: .plainX, target: self, action: #selector(closeButtonPressed), alignment: .leading)
        
        let searchBarConfig: WMFNavigationBarSearchConfig?
        if !self.hideLanguageFilter {
            let placeholder = WMFLocalizedString("article-languages-filter-placeholder", value: "Find language", comment: "Filter languages text box placeholder text.")
            searchBarConfig = WMFNavigationBarSearchConfig(
                searchResultsController: nil,
                searchControllerDelegate: nil,
                searchResultsUpdater: nil,
                searchBarDelegate: self,
                searchBarPlaceholder: placeholder,
                showsScopeBar: false,
                scopeButtonTitles: nil
            )
        } else {
            searchBarConfig = nil
        }
        
        configureNavigationBar(titleConfig: titleConfig, closeButtonConfig: closeButtonConfig, profileButtonConfig: nil, tabsButtonConfig: nil, searchBarConfig: searchBarConfig, hideNavigationBarOnScroll: false)
    }
    
    @objc private func closeButtonPressed() {
        self.dismiss(animated: true) {
            self.userDismissalCompletionBlock?()
        }
    }
}
