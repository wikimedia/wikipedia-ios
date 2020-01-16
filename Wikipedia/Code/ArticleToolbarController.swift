
import UIKit

protocol ArticleToolbarHandling: class {
    func toggleSave(from controller: ArticleToolbarController, shouldSave: Bool)
    func saveButtonWasLongPressed(from controller: ArticleToolbarController)
    func showThemePopover(from controller: ArticleToolbarController)
}

class ArticleToolbarController: Themeable {
    weak var delegate: ArticleToolbarHandling?
    
    let toolbar: UIToolbar
    private var isSaved: Bool = false //tonitodo: better state handling here
    
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

    init(toolbar: UIToolbar, delegate: ArticleToolbarHandling) {
        self.toolbar = toolbar
        self.delegate = delegate
        setup()
    }
    
    // MARK: Actions
    
    @objc func toggleSave(_ sender: UIBarButtonItem) {
        delegate?.toggleSave(from: self, shouldSave: !isSaved)
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
    
    // MARK: State
    
    func setSavedState(isSaved: Bool) {
        self.isSaved = isSaved
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
    }
}

private extension ArticleToolbarController {
    
    func setup() {
        toolbar.items = [saveButton, themeButton]
    }
}
