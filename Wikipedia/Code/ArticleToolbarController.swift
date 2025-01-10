import UIKit
import WMF
import WMFComponents
import WMFData

protocol ArticleToolbarHandling: AnyObject {
    func toggleSave(from controller: ArticleToolbarController)
    func saveButtonWasLongPressed(from controller: ArticleToolbarController)
    func showThemePopover(from controller: ArticleToolbarController)
    func showTableOfContents(from controller: ArticleToolbarController)
    func hideTableOfContents(from controller: ArticleToolbarController)
    func showLanguagePicker(from controller: ArticleToolbarController)
    func showFindInPage(from controller: ArticleToolbarController)
    func share(from controller: ArticleToolbarController)
    func showRevisionHistory(from controller: ArticleToolbarController)
    func showArticleTalkPage(from controller: ArticleToolbarController)
    func watch(from controller: ArticleToolbarController)
    func unwatch(from controller: ArticleToolbarController)
    func editArticle(from controller: ArticleToolbarController)
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
    
    lazy var moreButton: IconBarButtonItem = {
        let item = createMoreButton()
        item.accessibilityLabel = CommonStrings.moreButton
        item.accessibilityHint = CommonStrings.userMenuButtonAccesibilityText
        return item
    }()
    
    private func createMoreButton(needsWatchButton: Bool = false, needsUnwatchHalfButton: Bool = false, needsUnwatchFullButton: Bool = false) -> IconBarButtonItem {
        var actions: [UIAction] = []
        
        let image = WMFIcon.pencil
        actions.append(UIAction(title: CommonStrings.editSource, image: image, handler: { [weak self] _ in self?.tappedEditArticle() }))
        
        actions.append(UIAction(title: CommonStrings.articleRevisionHistory, image: UIImage(named: "edit-history"), handler: { [weak self] _ in self?.tappedRevisionHistory() }))
        
        actions.append(UIAction(title: CommonStrings.articleTalkPage, image: UIImage(systemName: "bubble.left.and.bubble.right"), handler: { [weak self] _ in self?.tappedArticleTalkPage() }))
        
        if needsWatchButton {
           actions.append(UIAction(title: CommonStrings.watch, image: UIImage(systemName: "star"), handler: { [weak self] _ in self?.tappedWatch() }))
        } else if needsUnwatchHalfButton {
            actions.append(UIAction(title: CommonStrings.unwatch, image: UIImage(systemName: "star.leadinghalf.filled"), handler: { [weak self] _ in self?.tappedUnwatch()}))
        } else if needsUnwatchFullButton {
            actions.append(UIAction(title: CommonStrings.unwatch, image: UIImage(systemName: "star.fill"), handler: { [weak self] _ in self?.tappedUnwatch()}))
        }

        actions.append(UIAction(title: CommonStrings.shortShareTitle, image: UIImage(systemName: "square.and.arrow.up"), handler: { [weak self] _ in self?.share()}))
        
        let menu = UIMenu(title: "", options: .displayInline, children: actions)
        
        let moreImage = UIImage(systemName: "ellipsis.circle", withConfiguration: UIImage.SymbolConfiguration(weight: .light))
        
        let item = IconBarButtonItem(image: moreImage, menu: menu)

        item.accessibilityLabel = CommonStrings.moreButton
        return item
    }
    
    func updateMoreButton(needsWatchButton: Bool = false, needsUnwatchHalfButton: Bool = false, needsUnwatchFullButton: Bool = false) {
        self.moreButton = createMoreButton(needsWatchButton: needsWatchButton, needsUnwatchHalfButton: needsUnwatchHalfButton, needsUnwatchFullButton: needsUnwatchFullButton)
        update()
    }
    
    var moreButtonSourceView: UIView {
        return toolbar
    }
    
    var moreButtonSourceRect: CGRect? {
        
        guard let findInPageButtonView = findInPageButton.customView,
              let themeButtonView = themeButton.customView else {
            return nil
        }
        
        return WatchlistController.calculateToolbarFifthButtonSourceRect(toolbarView: toolbar, thirdButtonView: findInPageButtonView, fourthButtonView: themeButtonView)
    }

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
    
    @objc func tappedArticleTalkPage() {
        delegate?.showArticleTalkPage(from: self)
    }
    
    @objc func tappedWatch() {
        delegate?.watch(from: self)
    }
    
    @objc func tappedUnwatch() {
        delegate?.unwatch(from: self)
    }
    
    @objc func tappedRevisionHistory() {
        delegate?.showRevisionHistory(from: self)
    }
    
    @objc func tappedEditArticle() {
        delegate?.editArticle(from: self)
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
            findInPageButton,
            UIBarButtonItem.flexibleSpaceToolbar(),
            themeButton,
            UIBarButtonItem.flexibleSpaceToolbar(),
            moreButton,
            UIBarButtonItem.flexibleSpaceToolbar()
        ]
    }

    func setToolbarButtons(enabled: Bool) {
        toolbar.items?.forEach { $0.isEnabled = enabled }
    }

}
