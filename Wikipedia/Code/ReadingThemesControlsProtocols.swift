import Foundation

fileprivate var fontSizeMultipliers: [Int] {
    
    return [WMFFontSizeMultiplier.extraSmall.rawValue,
            WMFFontSizeMultiplier.small.rawValue,
            WMFFontSizeMultiplier.medium.rawValue,
            WMFFontSizeMultiplier.large.rawValue,
            WMFFontSizeMultiplier.extraLarge.rawValue,
            WMFFontSizeMultiplier.extraExtraLarge.rawValue,
            WMFFontSizeMultiplier.extraExtraExtraLarge.rawValue]
}

fileprivate var indexOfCurrentFontSize: Int {
    get {
        let fontSize = UserDefaults.standard.wmf_articleFontSizeMultiplier()
        let index = fontSizeMultipliers.firstIndex(of: fontSize.intValue) ?? fontSizeMultipliers.count / 2
        return index
    }
}

protocol ReadingThemesControlsPresenting: UIPopoverPresentationControllerDelegate {
    var readingThemesControlsViewController: ReadingThemesControlsViewController { get }
    var readingThemesControlsToolbarItem: UIBarButtonItem { get }
    var shouldPassthroughNavBar: Bool { get }
    var showsSyntaxHighlighting: Bool { get }
}

protocol ReadingThemesControlsResponding: WMFReadingThemesControlsViewControllerDelegate {
    func updateWebViewTextSize(textSize: Int)
}

extension ReadingThemesControlsPresenting {
    
    func showReadingThemesControlsPopup(on viewController: UIViewController, responder: ReadingThemesControlsResponding, theme: Theme) {
        readingThemesControlsViewController.loadViewIfNeeded()
        
        let fontSizes = fontSizeMultipliers
        let index = indexOfCurrentFontSize
        
        readingThemesControlsViewController.modalPresentationStyle = .popover
        readingThemesControlsViewController.popoverPresentationController?.delegate = self
        
        readingThemesControlsViewController.delegate = responder
        readingThemesControlsViewController.setValuesWithSteps(fontSizes.count, current: index)
        readingThemesControlsViewController.showsSyntaxHighlighting = showsSyntaxHighlighting
        
        apply(presentationTheme: theme)
        
        let popoverPresenter = readingThemesControlsViewController.popoverPresentationController
        if let view = readingThemesControlsToolbarItem.customView {
            popoverPresenter?.sourceView = viewController.view
            popoverPresenter?.sourceRect = viewController.view.convert(view.bounds, from: view)
        } else {
            popoverPresenter?.barButtonItem = readingThemesControlsToolbarItem
        }
        popoverPresenter?.permittedArrowDirections = [.down, .up]
        
        if let navBar = viewController.navigationController?.navigationBar,
            shouldPassthroughNavBar {
            popoverPresenter?.passthroughViews = [navBar]
        }
        
        viewController.present(readingThemesControlsViewController, animated: true, completion: nil)
    }
    
    func dismissReadingThemesPopoverIfActive(from viewController: UIViewController) {
        if viewController.presentedViewController is ReadingThemesControlsViewController {
            viewController.dismiss(animated: true, completion: nil)
        }
    }
    
   func apply(presentationTheme theme: Theme) {
        readingThemesControlsViewController.apply(theme: theme)
        readingThemesControlsViewController.popoverPresentationController?.backgroundColor = theme.colors.popoverBackground
    }
}

extension WMFReadingThemesControlsViewControllerDelegate where Self: ReadingThemesControlsResponding {
    func fontSizeSliderValueChangedInController(_ controller: ReadingThemesControlsViewController, value: Int) {
        let fontSizes = fontSizeMultipliers
        
        if value > fontSizes.count {
            return
        }
        
        let multiplier = fontSizeMultipliers[value]
        let nsNumber = NSNumber(value: multiplier)
        UserDefaults.standard.wmf_setArticleFontSizeMultiplier(nsNumber)
        
        updateWebViewTextSize(textSize: multiplier)
    }
}

@objc(WMFReadingThemesControlsArticlePresenter)
class ReadingThemesControlsArticlePresenter: NSObject, ReadingThemesControlsPresenting {
    
    var shouldPassthroughNavBar: Bool {
        return true
    }
    
    var showsSyntaxHighlighting: Bool {
        return false
    }
    
    var readingThemesControlsViewController: ReadingThemesControlsViewController
    var readingThemesControlsToolbarItem: UIBarButtonItem
    private let wkWebView: WKWebView
    
    @objc var objcIndexOfCurrentFontSize: Int {
        return indexOfCurrentFontSize
    }
    
    @objc var objcFontSizeMultipliers: [Int] {
        return fontSizeMultipliers
    }
    
    @objc init(readingThemesControlsViewController: ReadingThemesControlsViewController, wkWebView: WKWebView, readingThemesControlsToolbarItem: UIBarButtonItem) {
        self.readingThemesControlsViewController = readingThemesControlsViewController
        self.wkWebView = wkWebView
        self.readingThemesControlsToolbarItem = readingThemesControlsToolbarItem
        super.init()
    }
    
    @objc func objCShowReadingThemesControlsPopup(on viewController: UIViewController, theme: Theme) {
        showReadingThemesControlsPopup(on: viewController, responder: self, theme: theme)
    }
    
    @objc func objCDismissReadingThemesPopoverIfActive(from viewController: UIViewController) {
        dismissReadingThemesPopoverIfActive(from: viewController)
    }

    @objc func objCApplyPresentationTheme(theme: Theme) {
        apply(presentationTheme: theme)
    }
    
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return .none
    }
    
    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        return .none
    }
}

extension ReadingThemesControlsArticlePresenter: ReadingThemesControlsResponding {
    func updateWebViewTextSize(textSize: Int) {
        wkWebView.wmf_setTextSize(textSize)
    }
    
    func toggleSyntaxHighlighting(_ controller: ReadingThemesControlsViewController) {
        //do nothing
    }
}
