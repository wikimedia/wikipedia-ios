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

    func showTooltips() {
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
        guard let dataController = WMFArticleTabsDataController.shared else {
            return
        }

        guard let navigationBar = self.navigationController?.navigationBar, let titleView = navigationItem.titleView else {
            return
        }

        let wIconTootipTitle = WMFLocalizedString("back-button-popover-title", value: "Tap to go back", comment: "Title for popover explaining the 'W' icon may be tapped to go back.")
        let wIconTootipBody = WMFLocalizedString("original-tab-button-popover-description", value: "Tap on the 'W' to return to the tab you started from", comment: "Description for popover explaining the 'W' icon may be tapped to return to the original tab.")
        let wTooltipStrings = WMFTooltipViewModel.LocalizedStrings(
            title: wIconTootipTitle, body: wIconTootipBody,
            buttonTitle: CommonStrings.gotItButtonTitle
        )

        let firstTooltipString = WMFTooltipViewModel.LocalizedStrings(
            title: WMFLocalizedString("open-in-tab-tooltip-title", value: "Open in new tab", comment: "Title for tooltip explaining the open in new tab functionality"),
            body:  WMFLocalizedString("open-in-tab-tooltip-body", value: "Long-press an article title or blue link to open it in a new tab.", comment: "Description for tooltip explaining the open in new tab functionality"),
            buttonTitle: CommonStrings.gotItButtonTitle
        )
        let secondTooltipString = WMFTooltipViewModel.LocalizedStrings(
            title: WMFLocalizedString("tabs-overview-tooltip-title", value: "Tabs overview", comment: "Title for tootltip explaining the tabs overview functionality"),
            body: WMFLocalizedString("tabs-overview-tooltip-body", value: "Switch between open articles in the tabs overview.", comment: "DEscription for tootltip explaining the tabs overview functionality"),
            buttonTitle: CommonStrings.gotItButtonTitle
        )

        let sourceRect = CGRect(x: navigationBar.bounds.width / 2, y: navigationBar.frame.maxY, width: 0, height: 0)

        guard sourceRect.origin.y > 0 else {
            return
        }

        let viewModel = WMFTooltipViewModel(localizedStrings: wTooltipStrings, buttonNeedsDisclosure: false, sourceView: navigationBar, sourceRect: sourceRect, permittedArrowDirections: .up, buttonAction: nil)
        let viewModel1 = WMFTooltipViewModel(localizedStrings: firstTooltipString, buttonNeedsDisclosure: false, sourceView: navigationBar, sourceRect: titleView.frame, permittedArrowDirections: .up) {

        }

        let paragraphTarget = self.firstParagraphRect ?? webView.convert(webView.bounds, to: view)
        let viewModel2 = WMFTooltipViewModel(localizedStrings: secondTooltipString, buttonNeedsDisclosure: false, sourceView: navigationBar, sourceRect: titleView.frame, permittedArrowDirections: .up) {

        }

        if dataController.shouldShowArticleTabs && !dataController.hasPresentedTooltips {
            if shouldShowWIconPopover {
                self.displayTooltips(tooltipViewModels: [viewModel, viewModel1, viewModel2])
                dataController.hasPresentedTooltips = true
            } else {
                self.displayTooltips(tooltipViewModels: [viewModel1, viewModel2])
                UserDefaults.standard.wmf_setDidShowWIconPopover(true)
                dataController.hasPresentedTooltips = true
            }
        } else if shouldShowWIconPopover {
            self.displayTooltips(tooltipViewModels: [viewModel])
            UserDefaults.standard.wmf_setDidShowWIconPopover(true)
        }
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

