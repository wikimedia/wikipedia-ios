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

        let openInTabVM = WMFTooltipViewModel(localizedStrings: makeOpenInTabStrings(), buttonNeedsDisclosure: false, sourceView: view, sourceRect: articleSourceRect) { [weak self] in
            guard let self else { return }
            if let siteURL = self.articleURL.wmf_site, let project = WikimediaProject(siteURL: siteURL) {
                ArticleTabsFunnel.shared.logTabTooltipImpression(project: project)
            }
            dataController.hasPresentedTooltips = true
        }

        let tabsOverviewVM = WMFTooltipViewModel(localizedStrings: makeTabsOverviewStrings(), buttonNeedsDisclosure: false, sourceView: navigationBar, sourceRect: squareRect, permittedArrowDirections: .up) { [weak self] in
            guard let self else { return }
            if let siteURL = self.articleURL.wmf_site, let project = WikimediaProject(siteURL: siteURL) {
                // logging icon impression here so it's only sent once
                ArticleTabsFunnel.shared.logTabIconFirstImpression(project: project)
            }
            dataController.hasPresentedTooltips = true
        }

        if !dataController.hasPresentedTooltips {
            tooltipViewModels = shouldShowWIconPopover ? [wIconVM, openInTabVM, tabsOverviewVM] : [openInTabVM, tabsOverviewVM]
        } else if shouldShowWIconPopover {
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

    private func makeOpenInTabStrings() -> WMFTooltipViewModel.LocalizedStrings {
        let title = WMFLocalizedString(
            "open-in-tab-tooltip-title",
            value: "Open in new tab",
            comment: "Title for tooltip explaining the open in new tab functionality"
        )
        let body = WMFLocalizedString(
            "open-in-tab-tooltip-body",
            value: "Long-press an article title or blue link to open it in a new tab.",
            comment: "Description for tooltip explaining the open in new tab functionality"
        )
        return WMFTooltipViewModel.LocalizedStrings(
            title: title,
            body: body,
            buttonTitle: CommonStrings.gotItButtonTitle
        )
    }

    private func makeTabsOverviewStrings() -> WMFTooltipViewModel.LocalizedStrings {
        let title = WMFLocalizedString(
            "tabs-overview-tooltip-title",
            value: "Tabs overview",
            comment: "Title for tooltip explaining the tabs overview functionality"
        )
        let body = WMFLocalizedString(
            "tabs-overview-tooltip-body",
            value: "Switch between open articles in the tabs overview.",
            comment: "Description for tooltip explaining the tabs overview functionality"
        )
        return WMFTooltipViewModel.LocalizedStrings(
            title: title,
            body: body,
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
