protocol EditMenuItemsControllerDelegate: class {
    func editMenuItemsControllerDidToggleBoldface(_ editMenuItemsController: EditMenuItemsController, menuItem: UIMenuItem)
    func editMenuItemsControllerDidToggleItalics(_ editMenuItemsController: EditMenuItemsController, menuItem: UIMenuItem)
}

class EditMenuItemsController: NSObject {
    weak var delegate: EditMenuItemsControllerDelegate?

    lazy var items: [UIMenuItem] = {
        let addCitation = UIMenuItem(title: "+", action: #selector(toggleCitation(_:)))
        let addLink = UIMenuItem(title: "🔗", action: #selector(toggleLink(_:)))
        let addCurlyBrackets = UIMenuItem(title: "{}", action: #selector(toggleCurlyBrackets(_:)))
        let makeBold = UIMenuItem(title: "𝗕", action: #selector(toggleBoldface(_:)))
        let makeItalic = UIMenuItem(title: "𝐼", action: #selector(toggleItalics(_:)))
        return [addCitation, addLink, addCurlyBrackets, makeBold, makeItalic]
    }()

    lazy var availableActions: [Selector] = {
        let actions = [
            #selector(WKWebView.cut(_:)),
            #selector(WKWebView.copy(_:)),
            #selector(EditMenuItemsController.toggleBoldface(_:)),
            #selector(EditMenuItemsController.toggleItalics(_:)),
            ]
        return actions
    }()

    @objc private func toggleBoldface(_ sender: UIMenuItem) {
        delegate?.editMenuItemsControllerDidToggleBoldface(self, menuItem: sender)
    }

    @objc private func toggleItalics(_ sender: UIMenuItem) {
        delegate?.editMenuItemsControllerDidToggleItalics(self, menuItem: sender)
    }

    @objc private func toggleCitation(_ sender: UIMenuItem) {

    }

    @objc private func toggleLink(_ sender: UIMenuItem) {

    }

    @objc private func toggleCurlyBrackets(_ sender: UIMenuItem) {

    }
}
