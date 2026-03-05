import WMFData
import WMFComponents
import WebKit
import TipKit

/// Article Tooltips
extension ArticleViewController {

    @objc func listenForTooltips() {
        wTipObservationTask =  Task { @MainActor [weak self] in
            guard let self else { return }
            
            for await status in wTip.statusUpdates {
                if status == .available {
                    if let wIcon = navigationItem.titleView {
                        let popoverController = TipUIPopoverViewController(wTip, sourceItem: wIcon)
                        self.tooltipVC = popoverController
                        present(popoverController, animated: true) {
                            popoverController.presentationController?.delegate = self
                        }
                    }
                } else if case .invalidated = status {
                    tooltipVC?.presentationController?.delegate = nil
                    tooltipVC?.dismiss(animated: true)
                    tooltipVC = nil
                    break
                }
            }
        }
    }
}

struct WTip: Tip {
    
    @Parameter
    static var isCompactWidth: Bool = false
    
    @Parameter
    static var willDisplayCampaignModal: Bool? = nil
    
    @Parameter
    static var willDisplayYearInReviewModal: Bool? = nil
    
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
                #Rule(Self.$willDisplayCampaignModal) { $0 == false },
                #Rule(Self.$willDisplayYearInReviewModal) { $0 == false }
            ]
        }
}

// MARK: - UIAdaptivePresentationControllerDelegate

extension ArticleViewController: UIAdaptivePresentationControllerDelegate {
    public func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        if presentationController.presentedViewController is TipUIPopoverViewController {
            wTip.invalidate(reason: .tipClosed)
        }
    }
}
