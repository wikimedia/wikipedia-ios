
import UIKit

protocol ArticleToolbarHandling: class {
    func toggleSave(from viewController: ArticleToolbarController, shouldSave: Bool)
}

class ArticleToolbarController {
    weak var delegate: ArticleToolbarHandling?
    let toolbar: UIToolbar
    private var isSaved: Bool = false //tonitodo: better state handling here
    
    lazy var saveButton: IconBarButtonItem = {
        let item = IconBarButtonItem(iconName: "save", target: self, action: #selector(toggleSave), for: .touchUpInside)
        return item
    }()

    init(toolbar: UIToolbar, delegate: ArticleToolbarHandling) {
        self.toolbar = toolbar
        self.delegate = delegate
        setup()
    }
    
    @objc func toggleSave(_ sender: UIBarButtonItem) {
        delegate?.toggleSave(from: self, shouldSave: !isSaved)
    }
    
    func setSavedState(isSaved: Bool) {
        self.isSaved = isSaved
        saveButton.accessibilityLabel = isSaved ? CommonStrings.accessibilitySavedTitle : CommonStrings.saveTitle
        if let innerButton = saveButton.customView as? UIButton {
            let assetName = isSaved ? "save-filled" : "save"
            innerButton.setImage(UIImage(named: assetName), for: .normal)
        }
    }
}

private extension ArticleToolbarController {
    
    func setup() {
        toolbar.items = [saveButton]
    }
}
