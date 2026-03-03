import WMFData
import WMFComponents
import WebKit
import TipKit

/// Article Tooltips
extension ArticleViewController {

    @objc func listenForTooltips() {
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
    
    @Parameter
    static var isCompactWidth: Bool = false
    static let didViewArticle: Event = Event(id: "didViewArticle")
    
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
    
    var rules: [Rule] {
      [
        #Rule(Self.$isCompactWidth) { $0 == true },
        #Rule(Self.didViewArticle) { $0.donations.count >= 3 }
      ]
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
