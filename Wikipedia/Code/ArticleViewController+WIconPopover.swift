import Foundation

/// W icon popover tooltip
extension ArticleViewController {
    var shouldShowWIconPopover: Bool {
        guard
            !UserDefaults.standard.wmf_didShowWIconPopover(),
            presentedViewController == nil,
            navigationController != nil,
            navigationBar.navigationBarPercentHidden < 0.1
        else {
            return false
        }
        return true
    }

    func showWIconPopoverIfNecessary() {
        guard shouldShowWIconPopover else {
            return
        }
        perform(#selector(showWIconPopover), with: nil, afterDelay: 1.0)
    }
    
    func cancelWIconPopoverDisplay() {
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(showWIconPopover), object: nil)
    }
    
    @objc func showWIconPopover() {
        let sourceRect = CGRect(x: navigationBar.bounds.width / 2, y: navigationBar.frame.maxY, width: 0, height: 0)
        
        guard sourceRect.origin.y > 0 else {
            return
        }
        
        let title = WMFLocalizedString("back-button-popover-title", value: "Tap to go back", comment: "Title for popover explaining the 'W' icon may be tapped to go back.")
        let message = WMFLocalizedString("original-tab-button-popover-description", value: "Tap on the 'W' to return to the tab you started from", comment: "Description for popover explaining the 'W' icon may be tapped to return to the original tab.")
        wmf_presentDynamicHeightPopoverViewController(sourceRect: sourceRect, title: title, message: message, width: 230, duration: 3)
        UserDefaults.standard.wmf_setDidShowWIconPopover(true)
    }
}
