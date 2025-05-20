import WMFData
import WMFComponents
import WebKit

/// W icon popover tooltip
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

        if let articleTabsDataController = WMFArticleTabsDataController.shared {
            if !articleTabsDataController.hasPresentedTooltips {
                return true
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
        guard let navigationBar = self.navigationController?.navigationBar else {
            return
        }
        
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

extension ArticleViewController {
    /// Tabs Tooltips
    func showTooltips() {
        perform(#selector(showTooltipsIfNecessary), with: nil, afterDelay: 1.0)
    }

    @objc private func showTooltipsIfNecessary() {
        guard WMFArticleTabsDataController.shared?.hasPresentedTooltips ?? false else { return }


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

        guard !dataController.hasPresentedTooltips else {
            return
        }

        guard let navigationBar = self.navigationController?.navigationBar else {
            return
        }

        let firstTooltipString = WMFTooltipViewModel.LocalizedStrings(title: "First tooltip title ", body: "Body", buttonTitle: "Got it")
        let secondTooltipString = WMFTooltipViewModel.LocalizedStrings(title: "Second tooltip title ", body: "Body", buttonTitle: "Got it")
        let thirdTooltipString = WMFTooltipViewModel.LocalizedStrings(title: "Third tooltip title ", body: "Body", buttonTitle: "Got it")

        let WIconRect = CGRect(x: navigationBar.bounds.width / 2, y: navigationBar.frame.maxY, width: 0, height: 0)
        let viewModel1 = WMFTooltipViewModel(localizedStrings: firstTooltipString, buttonNeedsDisclosure: false, sourceView: navigationBar, sourceRect: WIconRect, permittedArrowDirections: .up) {

        }

        let paragraphTarget = self.firstParagraphRect ?? webView.convert(webView.bounds, to: view)
        let viewModel2 = WMFTooltipViewModel(localizedStrings: secondTooltipString, buttonNeedsDisclosure: false, sourceView: webView, sourceRect: paragraphTarget, permittedArrowDirections: .down) {

        }

        let tabButtonRect = CGRect(x: navigationBar.bounds.width / 1.6, y: navigationBar.frame.maxY, width: 0, height: 0)
        let viewModel3 = WMFTooltipViewModel(localizedStrings: thirdTooltipString, buttonNeedsDisclosure: true, sourceView: navigationBar, sourceRect: tabButtonRect, permittedArrowDirections: .up) {

        }
        self.displayTooltips(tooltipViewModels: [viewModel1, viewModel2, viewModel3])
        dataController.hasPresentedTooltips = true

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

