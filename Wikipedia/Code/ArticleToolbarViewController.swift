
import UIKit

protocol ArticleToolbarHandling: class {
    func toggleSave(from viewController: ArticleToolbarViewController)
}

class ArticleToolbarViewController: UIViewController {
    
    private let toolbarView = UIToolbar()
    weak var delegate: ArticleToolbarHandling?
    
    lazy var saveButton: IconBarButtonItem = {
        let item = IconBarButtonItem(iconName: "save", target: self, action: #selector(toggleSave), for: .touchUpInside)
        return item
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        setup()
        toolbarView.backgroundColor = .green
    }
    
    @objc func toggleSave(_ sender: UIBarButtonItem) {
        delegate?.toggleSave(from: self)
    }
    
    func setSavedState(isSaved: Bool) {
        saveButton.accessibilityLabel = isSaved ? CommonStrings.accessibilitySavedTitle : CommonStrings.saveTitle
        if let innerButton = saveButton.customView as? UIButton {
            let assetName = isSaved ? "save-filled" : "save"
            innerButton.setImage(UIImage(named: assetName), for: .normal)
        }
    }
}

private extension ArticleToolbarViewController {
    
    func setup() {
        
        toolbarView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(toolbarView)
        view.wmf_addConstraintsToEdgesOfView(toolbarView)
        
        toolbarView.items = [saveButton]
    }
}
