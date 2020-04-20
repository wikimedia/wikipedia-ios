
import UIKit

protocol ArticleToolbarHandling: class {
    func toggleSave(from controller: ArticleToolbarController)
    func saveButtonWasLongPressed(from controller: ArticleToolbarController)
    func showThemePopover(from controller: ArticleToolbarController)
    func showTableOfContents(from controller: ArticleToolbarController)
    func hideTableOfContents(from controller: ArticleToolbarController)
    func showLanguagePicker(from controller: ArticleToolbarController)
    func showFindInPage(from controller: ArticleToolbarController)
    func share(from controller: ArticleToolbarController)
    var isTableOfContentsVisible: Bool { get }
}

class ArticleToolbarController: Themeable {
    weak var delegate: ArticleToolbarHandling?
    
    let toolbar: UIToolbar
    
    lazy var saveButton: IconBarButtonItem = {
        let item = IconBarButtonItem(iconName: "save", target: self, action: #selector(toggleSave), for: .touchUpInside)
        let longPressGR = UILongPressGestureRecognizer(target: self, action: #selector(handleSaveButtonLongPress))
        if let button = item.customView as? UIButton {
            button.addGestureRecognizer(longPressGR)
        }
        item.apply(theme: theme)
        return item
    }()
    
    lazy var themeButton: IconBarButtonItem = {
        let item = IconBarButtonItem(iconName: "font-size", target: self, action: #selector(showThemes), for: .touchUpInside)
        item.apply(theme: theme)
        return item
    }()
    
    lazy var showTableOfContentsButton: IconBarButtonItem = {
        let item = IconBarButtonItem(iconName: "toc", target: self, action: #selector(showTableOfContents), for: .touchUpInside)
        item.accessibilityLabel = WMFLocalizedString("table-of-contents-button-label", value: "Table of contents", comment: "Accessibility label for the Table of Contents button {{Identical|Table of contents}}")
        item.apply(theme: theme)
        return item
    }()
    
    lazy var shareButton: IconBarButtonItem = {
        let item = IconBarButtonItem(iconName: "share", target: self, action: #selector(share), for: .touchUpInside)
        item.accessibilityLabel = CommonStrings.accessibilityShareTitle
        item.apply(theme: theme)
        return item
    }()
    
    lazy var findInPageButton: IconBarButtonItem = {
        let item = IconBarButtonItem(iconName: "find-in-page", target: self, action: #selector(findInPage), for: .touchUpInside)
        item.accessibilityLabel = CommonStrings.findInPage
        item.apply(theme: theme)
        return item
    }()
    
    lazy var hideTableOfContentsButton: IconBarButtonItem = {
        let item = IconBarButtonItem(iconName: "toc", target: self, action: #selector(hideTableOfContents), for: .touchUpInside)
        if let button = item.customView as? UIButton {
            button.layer.cornerRadius = 5
            button.layer.masksToBounds = true
        }
        item.accessibilityLabel = WMFLocalizedString("table-of-contents-hide-button-label", value: "Hide table of contents", comment: "Accessibility label for the hide Table of Contents button")
        item.apply(theme: theme)
        return item
    }()
    
    lazy var languagesButton: IconBarButtonItem = {
        let item = IconBarButtonItem(iconName: "language", target: self, action: #selector(showLanguagePicker), for: .touchUpInside)
        item.accessibilityLabel = CommonStrings.accessibilityLanguagesTitle
        item.apply(theme: theme)
        return item
    }()

    init(toolbar: UIToolbar, delegate: ArticleToolbarHandling) {
        self.toolbar = toolbar
        self.delegate = delegate
        update()
    }
    
    // MARK: Actions
    
    @objc func toggleSave(_ sender: UIBarButtonItem) {
        delegate?.toggleSave(from: self)
    }
    
    @objc func handleSaveButtonLongPress(_ longPressGestureRecognizer: UILongPressGestureRecognizer) {
        guard longPressGestureRecognizer.state == .began else {
            return
        }
        delegate?.saveButtonWasLongPressed(from: self)
    }
    
    @objc func showThemes() {
        delegate?.showThemePopover(from: self)
    }
    
    @objc func showTableOfContents() {
        delegate?.showTableOfContents(from: self)
    }
    
    @objc func hideTableOfContents() {
        delegate?.hideTableOfContents(from: self)
    }
    
    @objc func showLanguagePicker() {
        delegate?.showLanguagePicker(from: self)
    }
    
    @objc func share() {
        delegate?.share(from: self)
    }
    
    @objc func findInPage() {
        delegate?.showFindInPage(from: self)
    }
    
    // MARK: State
    
    func setSavedState(isSaved: Bool) {
        saveButton.accessibilityLabel = isSaved ? CommonStrings.accessibilitySavedTitle : CommonStrings.saveTitle
        if let innerButton = saveButton.customView as? UIButton {
            let assetName = isSaved ? "save-filled" : "save"
            innerButton.setImage(UIImage(named: assetName), for: .normal)
        }
    }
    
    // MARK: Theme
    
    var theme: Theme = Theme.standard
    
    func apply(theme: Theme) {
        for item in toolbar.items ?? [] {
            guard let item = item as? Themeable else {
                continue
            }
            item.apply(theme: theme)
        }
        hideTableOfContentsButton.customView?.backgroundColor = theme.colors.midBackground
    }
    
    func override(items: [UIBarButtonItem]) {
        // disable updating here if that's ever a thing
        toolbar.items = items
    }
    
    func update() {
        let tocItem = delegate?.isTableOfContentsVisible ?? false ? hideTableOfContentsButton : showTableOfContentsButton
        toolbar.items = [
            UIBarButtonItem.flexibleSpaceToolbar(),
            tocItem,
            UIBarButtonItem.flexibleSpaceToolbar(),
            languagesButton,
            UIBarButtonItem.flexibleSpaceToolbar(),
            saveButton,
            UIBarButtonItem.flexibleSpaceToolbar(),
            shareButton,
            UIBarButtonItem.flexibleSpaceToolbar(),
            themeButton,
            UIBarButtonItem.flexibleSpaceToolbar(),
            findInPageButton,
            UIBarButtonItem.flexibleSpaceToolbar()
        ]
    }

    func setToolbarButtons(enabled: Bool) {
        toolbar.items?.forEach { $0.isEnabled = enabled }
    }

}
