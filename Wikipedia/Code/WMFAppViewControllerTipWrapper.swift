import TipKit
import SwiftUI

/// Wrapper class to call TipKit APIs from Objective-C
@objc class WMFAppViewControllerTipWrapper: NSObject {
    
    fileprivate var tip = HistoryInSearchTip()
    fileprivate var tipObservationTask: Task<Void, Never>?
    weak var tooltipVC: TipUIPopoverViewController?
    
    @objc func listenForTooltips(appViewController: WMFAppViewController, tabBarItem: UITabBarItem) {
        tipObservationTask =  Task { @MainActor [weak self, weak appViewController] in
            guard let self, let appViewController else { return }
            
            for await status in tip.statusUpdates {
                if status == .available {
                    let popoverController = TipUIPopoverViewController(tip, sourceItem: tabBarItem)
                    self.tooltipVC = popoverController
                    appViewController.present(popoverController, animated: true) {
                        popoverController.presentationController?.delegate = self
                    }
                } else if case .invalidated = status {
                    tooltipVC?.presentationController?.delegate = nil
                    tooltipVC?.dismiss(animated: true)
                    tooltipVC = nil
                    self.tipObservationTask = nil
                    break
                }
            }
        }
    }
}

// MARK: - UIAdaptivePresentationControllerDelegate

extension WMFAppViewControllerTipWrapper: UIAdaptivePresentationControllerDelegate {
    public func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        if presentationController.presentedViewController is TipUIPopoverViewController {
            tip.invalidate(reason: .tipClosed)
        }
    }
}


fileprivate struct HistoryInSearchTip: Tip {
    
    var title: Text {
        Text(WMFLocalizedString(
            "tip-history-in-search-title",
            value: "History moved to Search",
            comment: "Title for one-time tooltip informing users history has moved to search."
        ))
    }
    
    var message: Text? {
        Text(WMFLocalizedString(
            "tip-history-in-search-subtitle",
            value: "Find your reading history in the Search tab.",
            comment: "Subtitle for one-time tooltip informing users history has moved to search."
        ))
    }
    
    var image: SwiftUI.Image? {
        return nil
    }
}
