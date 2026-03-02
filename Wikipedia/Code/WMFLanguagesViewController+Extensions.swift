import Foundation
import WMFComponents

extension WMFLanguagesViewController: WMFNavigationBarConfiguring {
    
    @objc func configureNavigationBarFromObjC(title: String) {
        let titleConfig = WMFNavigationBarTitleConfig(title: title, customView: nil, alignment: .centerCompact)
        let closeButtonConfig = WMFLargeCloseButtonConfig(imageType: .plainX, target: self, action: #selector(closeButtonPressed), alignment: .leading)
        configureNavigationBar(titleConfig: titleConfig, closeButtonConfig: closeButtonConfig, profileButtonConfig: nil, tabsButtonConfig: nil, searchBarConfig: nil, hideNavigationBarOnScroll: false)
    }
    
    @objc func updateEditButton(isEditing: Bool) {
        if isEditing {
            let doneButtonConfig = WMFLargeCloseButtonConfig(imageType: .prominentCheck, target: self, action: #selector(doneButtonPressed), alignment: .trailing)
            navigationItem.rightBarButtonItem = UIBarButtonItem.closeNavigationBarButtonItem(config: doneButtonConfig)
        } else {
            navigationItem.rightBarButtonItem = editButtonItem
        }
    }
    
    @objc private func closeButtonPressed() {
        self.dismiss(animated: true) {
            self.userDismissalCompletionBlock?()
        }
    }
    
    @objc private func doneButtonPressed() {
        self.dismiss(animated: true) {
            self.userDismissalCompletionBlock?()
        }
    }
}
