import TipKit
import SwiftUI
import WMFComponents

/// Wrapper class to call TipKit APIs from Objective-C
@objc class WMFAppViewControllerTipWrapper: NSObject {
    
    fileprivate var tip = HistoryInSearchTip()
    fileprivate var tipObservationTask: Task<Void, Never>?
    weak var tooltipVC: TipUIPopoverViewController?
    
    lazy var tabSearchTargetViewIPad: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .clear
        return view
    }()
    
    private var tooltipEndDate: Date? {
        var dateComponents = DateComponents()
        dateComponents.month = 5
        dateComponents.day = 1
        dateComponents.year = 2026
        return Calendar.current.date(from: dateComponents)
    }
    
    @objc func listenForTooltips(appViewController: WMFAppViewController) {
        
        guard let endDate = tooltipEndDate,
              Date.now < endDate,
        (appViewController.viewControllers?.count ?? 0) == 5,
        let searchTabBarItem = appViewController.viewControllers?[4].tabBarItem else {
            return
        }
        
        // Only display on Explore
        guard appViewController.selectedIndex == 0,
        (appViewController.currentTabNavigationController?.viewControllers.count ?? 0) == 1 else {
            return
        }

        tipObservationTask =  Task { @MainActor [weak self, weak appViewController] in
            guard let self, let appViewController else { return }
            
            for await status in tip.statusUpdates {
                if status == .available {
                    
                    let popoverController = TipUIPopoverViewController(tip, sourceItem: searchTabBarItem)
                    popoverController.overrideUserInterfaceStyle = appViewController.theme.isDark ? .dark : .light
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
