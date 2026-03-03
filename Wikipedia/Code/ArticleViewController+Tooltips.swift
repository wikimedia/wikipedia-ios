import WMFData
import WMFComponents
import WebKit
import TipKit

/// Article Tooltips
extension ArticleViewController {
    
    var shouldShowWIconPopover: Bool {

        guard navigationController != nil else {
            return false
        }

        if #available(iOS 18, *) {
            if UIDevice.current.userInterfaceIdiom == .pad && traitCollection.horizontalSizeClass == .regular {
                return false
            }
        }

        guard
            presentedViewController == nil
        else {
            return false
        }
        return true
    }
    
    func cancelWIconPopoverDisplay() {
       NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(showTooltipsIfNecessary), object: nil)
   }

    func presentTooltipsIfNeeded() {
        perform(#selector(showTooltipsIfNecessary), with: nil, afterDelay: 1.0)
    }
    
    func needsTooltips() -> Bool {
        if shouldShowWIconPopover {
            return true
        }
        
        return false
    }

    @objc private func showTooltipsIfNecessary() {
        
        guard let navigationBar = navigationController?.navigationBar,
              !navigationBar.isHidden
        else {
            return
        }
        

        wTipObservationTask =  Task { @MainActor in
            for await status in wTip.statusUpdates {
                if status == .available {
                    if let wIcon = navigationItem.titleView {
                        let popoverController = TipUIPopoverViewController(wTip, sourceItem: wIcon)
                        present(popoverController, animated: true) {
                            popoverController.presentationController?.delegate = self
                        }
                        tipPopoverController = popoverController
                    }
                } else if case .invalidated = status {
                    // if presentedViewController is TipUIPopoverViewController {
                        dismiss(animated: true) { [weak self] in
                            guard let self else { return }
                            nextTipObservationTask = Task { @MainActor in
                                NextTip.enableTip = true
                                for await status in self.nextTip.statusUpdates {
                                    if status == .available {
                                        // try? await Task.sleep(for: .milliseconds(500))
                                        if let wIcon = self.navigationItem.titleView {
                                            let popoverController = TipUIPopoverViewController(self.nextTip, sourceItem: wIcon)
                                            self.present(popoverController, animated: true)
                                            self.tipPopoverController = popoverController
                                        }
                                    } else {
                                        if self.presentedViewController is TipUIPopoverViewController {
                                            self.dismiss(animated: true)
                                            self.tipPopoverController = nil
                                        }
                                    }
                                }
                            }
                        }
                        tipPopoverController = nil
                    // }
                    break
                }
            }
        }
    }
}

struct WTip: Tip {
    var title: Text {
        Text(WMFLocalizedString(
            "back-button-popover-title",
            value: "Tap to go back",
            comment: "Title for popover explaining the 'W' icon may be tapped to go back."
        ))
    }
    
    var message: Text? {
        Text(WMFLocalizedString(
            "original-tab-button-popover-description",
            value: "Tap on the 'W' to return to the tab you started from",
            comment: "Description for popover explaining the 'W' icon may be tapped to return to the original tab."
        ))
    }
    
    var image: SwiftUI.Image? {
        return nil
    }
}


struct NextTip: Tip {
    
    @Parameter static var enableTip: Bool = false
    
    var id: String {
        "NextTip"
    }
    
    var title: Text {
        Text("NextTip Title")
    }
    
    var message: Text? {
        Text("Message for the tip")
    }
    
    var image: SwiftUI.Image? {
        Image(systemName: "lightbulb.fill")
    }
    
    var rules: [Rule] {
        [
            #Rule(Self.$enableTip) { $0 == true }
        ]
    }
}

// MARK: - UIAdaptivePresentationControllerDelegate

extension ArticleViewController: UIAdaptivePresentationControllerDelegate {
    public func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        if presentationController.presentedViewController is TipUIPopoverViewController {
            wTip.invalidate(reason: .tipClosed)
            tipPopoverController = nil
        }
    }
}
