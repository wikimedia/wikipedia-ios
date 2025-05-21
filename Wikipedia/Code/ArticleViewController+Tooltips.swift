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

    @objc private func showTooltipsIfNecessary() {

        webView.firstParagraphFrame(in: webView) { [weak self] rect in
            guard let self = self else { return }

            self.firstParagraphRect = rect

            self.presentAllTooltips()
        }
    }

    private func presentAllTooltips() {
        guard
            let dataController = WMFArticleTabsDataController.shared,
            let navigationBar = navigationController?.navigationBar
        else {
            return
        }

        guard let wIconRect = computeWIconSourceRect(in: navigationBar) else {
            return
        }

        let paragraphRect = firstParagraphRect ?? webView.convert(webView.bounds, to: view)
        let squareRect = computeTabsIconSourceRect(in: navigationBar)

        let wIconVM = WMFTooltipViewModel(localizedStrings: makeWIconStrings(), buttonNeedsDisclosure: false, sourceView: navigationBar, sourceRect: wIconRect, permittedArrowDirections: .up) {

        }

        let openInTabVM = WMFTooltipViewModel(localizedStrings: makeOpenInTabStrings(), buttonNeedsDisclosure: false, sourceView: webView, sourceRect: paragraphRect, permittedArrowDirections: .down) {

        }

        let tabsOverviewVM = WMFTooltipViewModel(localizedStrings: makeTabsOverviewStrings(), buttonNeedsDisclosure: false, sourceView: navigationBar, sourceRect: squareRect, permittedArrowDirections: .up) {

        }

        guard dataController.shouldShowArticleTabs || shouldShowWIconPopover else {
            return
        }
        var viewModels: [WMFTooltipViewModel] = []

        if dataController.shouldShowArticleTabs && !dataController.hasPresentedTooltips {
            viewModels = shouldShowWIconPopover ? [wIconVM, openInTabVM, tabsOverviewVM] : [openInTabVM, tabsOverviewVM]
        } else if shouldShowWIconPopover {
            viewModels = [wIconVM]
        }

        if shouldShowWIconPopover {
            UserDefaults.standard.wmf_setDidShowWIconPopover(true)
        }

        if !viewModels.isEmpty {
            displayTooltips(tooltipViewModels: viewModels)
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
        let indexFromTrailing: CGFloat = 1 // second from right
        let margin = navBar.layoutMargins.right
        let hitWidth: CGFloat = 44
        let spacing: CGFloat  = 8

        let offsetFromTrailing =
        hitWidth * (indexFromTrailing + 0.5)
        + spacing * indexFromTrailing
        + margin
        let x = navBar.bounds.width - offsetFromTrailing
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

private extension WKWebView {
    /// Asynchronously finds the first paragraph in the page and returns its frame
    /// in the coordinate space of `containerView`.
    func firstParagraphFrame(in containerView: UIView,
                             completion: @escaping (CGRect?) -> Void) {
        let js = """
        (function(){
          var p = document.querySelector('.mw-parser-output > p:not(.mw-empty-elt)');
          if (!p) { return null; }
          var r = p.getBoundingClientRect();
          var scrollY = window.scrollY || window.pageYOffset;
          var scale   = window.devicePixelRatio || 1;
          return {
            x:      r.left/scale,
            y:     (r.top + scrollY)/scale,
            width:  r.width/scale,
            height: r.height/scale
          };
        })();
        """

        evaluateJavaScript(js) { result, error in
            guard
                error == nil,
                let dict = result as? [String: Any],
                let x     = dict["x"]     as? CGFloat,
                let y     = dict["y"]     as? CGFloat,
                let w     = dict["width"] as? CGFloat,
                let h     = dict["height"]as? CGFloat
            else {
                completion(nil)
                return
            }

            let paragraphRect = CGRect(x: x, y: y, width: w, height: h)

            let rectInContainer = self.convert(paragraphRect, to: containerView)
            completion(rectInContainer)
        }
    }
}

