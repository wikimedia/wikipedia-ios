import WMFData
import WMFComponents
import WebKit

/// Article Tooltips
extension ArticleViewController {
    var shouldShowWIconPopover: Bool {

        guard let navigationController else {
            return false
        }

        if #available(iOS 18, *) {
            if UIDevice.current.userInterfaceIdiom == .pad && traitCollection.horizontalSizeClass == .regular {
                return false
            }
        }

        guard
            !UserDefaults.standard.wmf_didShowWIconPopover(),
            presentedViewController == nil,
            !navigationController.isNavigationBarHidden
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
        if !WMFArticleTabsDataController.shared.hasPresentedTooltips || shouldShowWIconPopover {
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

        let dataController = WMFArticleTabsDataController.shared

        guard let wIconRect = computeWIconSourceRect(in: navigationBar) else {
            return
        }

        let squareRect = computeTabsIconSourceRect(in: navigationBar)

        let wIconVM = WMFTooltipViewModel(localizedStrings: makeWIconStrings(), buttonNeedsDisclosure: false, sourceView: navigationBar, sourceRect: wIconRect, permittedArrowDirections: .up) {
            UserDefaults.standard.wmf_setDidShowWIconPopover(true)
        }

        guard let articleSourceRect = computeApproximateTextSourceRect() else { return }


        if !dataController.hasPresentedTooltips  && shouldShowWIconPopover {
            tooltipViewModels = [wIconVM]
        }

        if !tooltipViewModels.isEmpty {
            displayTooltips(tooltipViewModels: tooltipViewModels)
        }
    }

    // MARK: – Private helper functions

    private func makeWIconStrings() -> WMFTooltipViewModel.LocalizedStrings {
        let title = WMFLocalizedString(
            "back-button-popover-title",
            value: "Tap to go back",
            comment: "Title for popover explaining the 'W' icon may be tapped to go back."
        )
        let body = WMFLocalizedString(
            "original-tab-button-popover-description",
            value: "Tap on the 'W' to return to the tab you started from",
            comment: "Description for popover explaining the 'W' icon may be tapped to return to the original tab."
        )
        return WMFTooltipViewModel.LocalizedStrings(
            title: title, body: body,
            buttonTitle: CommonStrings.gotItButtonTitle
        )
    }

    private func computeApproximateTextSourceRect() -> CGRect? {
        guard
            let navBar = navigationController?.navigationBar

        else {
            return nil
        }
        let leadImageHeight = leadImageHeightConstraint.constant
        let navBarBottomY   = navBar.frame.maxY
        let titleHeight: CGFloat =  44
        let padding: CGFloat = 12

        let yPos = navBarBottomY
        + leadImageHeight
        + titleHeight
        + padding
        let xPos = view.bounds.midX

        return CGRect(x: xPos, y: yPos, width: 0, height: 0)
    }

    private func computeWIconSourceRect(in navBar: UINavigationBar) -> CGRect? {
        let minY: CGFloat
        if
            let sb = navigationItem.searchController?.searchBar,
            let sbSuper = sb.superview {
            let frameInBar = navBar.convert(sb.frame, from: sbSuper)
            minY = frameInBar.minY
        } else {

            minY = navBar.bounds.height
        }
        guard minY > 0 else { return nil }
        return CGRect(x: navBar.bounds.midX, y: minY, width: 0, height: 0)
    }

    private func computeTabsIconSourceRect(in navBar: UINavigationBar) -> CGRect {
        let indexFromTrailing: CGFloat = 1
        let margin: CGFloat
        let layoutDirection = navBar.effectiveUserInterfaceLayoutDirection

        let hitWidth: CGFloat = 44
        let spacing: CGFloat  = 8
        let offsetFromEdge = hitWidth * (indexFromTrailing + 0.5) + spacing * indexFromTrailing

        let x: CGFloat
        switch layoutDirection {
        case .leftToRight:
            margin = navBar.layoutMargins.right
            x = navBar.bounds.width - (offsetFromEdge + margin)
        case .rightToLeft:
            margin = navBar.layoutMargins.left
            x = offsetFromEdge + margin
        @unknown default:
            margin = navBar.layoutMargins.right
            x = navBar.bounds.width - (offsetFromEdge + margin)
        }

        let minY: CGFloat
        if let sb = navigationItem.searchController?.searchBar,
           let sbSuper = sb.superview {
            let frameInBar = navBar.convert(sb.frame, from: sbSuper)
            minY = frameInBar.minY
        } else {
            minY = navBar.bounds.height
        }
        return CGRect(x: x, y: minY, width: 0, height: 0)
    }
}

extension ArticleViewController: WMFTooltipPresenting {

    public func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return .none
    }

    public func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        return .none
    }

    public func presentationControllerShouldDismiss(_ presentationController: UIPresentationController) -> Bool {

        // Tooltips are only allowed to dismiss via Next buttons
        if presentationController.presentedViewController is WMFTooltipViewController {
            return false
        }

        return true
    }

}
