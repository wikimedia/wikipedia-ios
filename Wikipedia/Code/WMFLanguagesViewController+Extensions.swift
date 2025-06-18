import Foundation
import WMFComponents

extension WMFLanguagesViewController: WMFNavigationBarConfiguring {
    
    @objc func configureNavigationBarFromObjC(title: String) {
        let titleConfig: WMFNavigationBarTitleConfig = WMFNavigationBarTitleConfig(title: title, customView: nil, alignment: .centerCompact)
        let closeButtonConfig = WMFNavigationBarCloseButtonConfig(text: CommonStrings.cancelActionTitle, target: self, action: #selector(closeButtonPressed), alignment: .leading)
        configureNavigationBar(titleConfig: titleConfig, closeButtonConfig: closeButtonConfig, profileButtonConfig: nil, tabsButtonConfig: nil, searchBarConfig: nil, hideNavigationBarOnScroll: false)
    }
    
    @objc private func closeButtonPressed() {
        self.dismiss(animated: true) {
            self.userDismissalCompletionBlock?()
        }
    }
}
