//
//  ReadingThemesControlsPresenter.swift
//  Wikipedia
//
//  Created by Toni Sevener on 2/27/19.
//  Copyright © 2019 Wikimedia Foundation. All rights reserved.
//

import Foundation

protocol ReadingThemesControlsPresenterProtocol: WMFReadingThemesControlsViewControllerDelegate, UIPopoverPresentationControllerDelegate {
    var readingThemesControlsViewController: ReadingThemesControlsViewController { get } //lazy loaded
    var wkWebView: WKWebView { get }
    var readingThemesControlsToolbarItem: UIBarButtonItem { get }
    var passthroughNavBar: Bool { get }
    var syntaxHighlighting: Bool { get }
    var toggleSyntaxHighlightingBlock: (() -> Void)? { get }
    var fontSizeChangedBlock: ((Int) -> Void)? { get }
}

extension ReadingThemesControlsPresenterProtocol {
    
    var fontSizeMultipliers: [Int] {

        return [WMFFontSizeMultiplier.extraSmall.rawValue,
                WMFFontSizeMultiplier.small.rawValue,
                WMFFontSizeMultiplier.medium.rawValue,
                WMFFontSizeMultiplier.large.rawValue,
                WMFFontSizeMultiplier.extraLarge.rawValue,
                WMFFontSizeMultiplier.extraExtraLarge.rawValue,
                WMFFontSizeMultiplier.extraExtraExtraLarge.rawValue]
    }
    
    var indexOfCurrentFontSize: Int {
        get {
            let fontSize = UserDefaults.wmf.wmf_articleFontSizeMultiplier()
            let index = fontSizeMultipliers.firstIndex(of: fontSize.intValue) ?? fontSizeMultipliers.count / 2
            return index
        }
    }
    
    func showReadingThemesControlsPopup(on viewController: UIViewController, theme: Theme) {
        
        let fontSizes = fontSizeMultipliers
        let index = indexOfCurrentFontSize
        
        readingThemesControlsViewController.modalPresentationStyle = .popover
        readingThemesControlsViewController.popoverPresentationController?.delegate = self
        
        readingThemesControlsViewController.delegate = self
        readingThemesControlsViewController.setValuesWithSteps(fontSizes.count, current: index)
        readingThemesControlsViewController.apply(theme: theme)
        readingThemesControlsViewController.syntaxHighlighting = syntaxHighlighting
        
        let popoverPresentationController = readingThemesControlsViewController.popoverPresentationController
        
        popoverPresentationController?.barButtonItem = readingThemesControlsToolbarItem
        popoverPresentationController?.permittedArrowDirections = [.down, .up]
        popoverPresentationController?.backgroundColor = theme.colors.popoverBackground
        viewController.present(readingThemesControlsViewController, animated: true, completion: nil)
        
        if let navBar = viewController.navigationController?.navigationBar,
            passthroughNavBar {
            popoverPresentationController?.passthroughViews = [navBar]
        }
    }
    
    func dismissReadingThemesPopoverIfActive(from viewController: UIViewController) {
        if viewController.presentedViewController is ReadingThemesControlsViewController {
            viewController.dismiss(animated: true, completion: nil)
        }
    }
    
    //MARK: WMFReadingThemesControlsViewControllerDelegate
    
    func fontSizeSliderValueChangedInController(_ controller: ReadingThemesControlsViewController, value: Int) {
        let fontSizes = fontSizeMultipliers
        
        if value > fontSizes.count {
            return
        }
        
        let multiplier = fontSizeMultipliers[value]
        let nsNumber = NSNumber(value: multiplier)
        wkWebView.wmf_setTextSize(multiplier)
        UserDefaults.wmf.wmf_setArticleFontSizeMultiplier(nsNumber)
        
        fontSizeChangedBlock?(multiplier)
    }
    
    func toggleSyntaxHighlighting(_ controller: ReadingThemesControlsViewController) {
        toggleSyntaxHighlightingBlock?()
    }
}

//objective-c wrapper for Article presentation.
@objc(WMFReadingThemesControlsPresenter)
class ReadingThemesControlsPresenter: NSObject, ReadingThemesControlsPresenterProtocol {
    
    //TODO: why doesn't Article VC need these blocks...
    var fontSizeChangedBlock: ((Int) -> Void)? {
        return nil
    }
    
    var toggleSyntaxHighlightingBlock: (() -> Void)? {
        return nil
    }
    
    var passthroughNavBar: Bool {
        return true
    }
    
    var syntaxHighlighting: Bool {
        return false
    }
    
    var readingThemesControlsViewController: ReadingThemesControlsViewController
    
    var wkWebView: WKWebView
    
    var readingThemesControlsToolbarItem: UIBarButtonItem
    
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
        showReadingThemesControlsPopup(on: viewController, theme: theme)
    }
    
    @objc func objCDismissReadingThemesPopoverIfActive(from viewController: UIViewController) {
        dismissReadingThemesPopoverIfActive(from: viewController)
    }
    
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return .none
    }
    
    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        return .none
    }
}
