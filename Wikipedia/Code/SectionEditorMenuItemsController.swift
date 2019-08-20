protocol SectionEditorMenuItemsDataSource: class {
    var availableMenuActions: [Selector] { get }
}

protocol SectionEditorMenuItemsDelegate: class {
    func sectionEditorWebViewDidTapSelectAll(_ sectionEditorWebView: SectionEditorWebView)
    func sectionEditorWebViewDidTapBoldface(_ sectionEditorWebView: SectionEditorWebView)
    func sectionEditorWebViewDidTapItalics(_ sectionEditorWebView: SectionEditorWebView)
    func sectionEditorWebViewDidTapCitation(_ sectionEditorWebView: SectionEditorWebView)
    func sectionEditorWebViewDidTapLink(_ sectionEditorWebView: SectionEditorWebView)
    func sectionEditorWebViewDidTapTemplate(_ sectionEditorWebView: SectionEditorWebView)
}

protocol SectionEditorMenuItemsControllerDelegate: AnyObject {
    func sectionEditorMenuItemsControllerDidTapLink(_ sectionEditorMenuItemsController: SectionEditorMenuItemsController)
}

class SectionEditorMenuItemsController: NSObject, SectionEditorMenuItemsDataSource {
    let messagingController: SectionEditorWebViewMessagingController

    init(messagingController: SectionEditorWebViewMessagingController) {
        self.messagingController = messagingController
        super.init()
        setEditMenuItems()
    }

    weak var delegate: SectionEditorMenuItemsControllerDelegate?

    // Keep original menu items
    // so that we can bring them back
    // when web view disappears
    var originalMenuItems: [UIMenuItem]?

    func setEditMenuItems() {
        if (originalMenuItems == nil){
            originalMenuItems = UIMenuController.shared.menuItems
        }
        var menuItems = self.menuItems
        messagingController.getLink { link in
            defer {
                UIMenuController.shared.menuItems = menuItems
            }
            guard let link = link else {
                return
            }
            let title = link.exists ? CommonStrings.editLinkTitle : CommonStrings.insertLinkTitle
            let linkItem = UIMenuItem(title: title, action: #selector(SectionEditorWebView.toggleLink(menuItem:)))
            menuItems.append(linkItem)
        }
    }

    var menuItems: [UIMenuItem] = {
        let addCitation = UIMenuItem(title: WMFLocalizedString("add-citation-title", value: "Add citation", comment: "Title for add citation action"), action: #selector(SectionEditorWebView.toggleCitation(menuItem:)))
        let addTemplate = UIMenuItem(title: "｛ ｝", action: #selector(SectionEditorWebView.toggleTemplate(menuItem:)))
        let makeBold = UIMenuItem(title: "𝗕", action: #selector(SectionEditorWebView.toggleBoldface(menuItem:)))
        let makeItalic = UIMenuItem(title: "𝐼", action: #selector(SectionEditorWebView.toggleItalics(menuItem:)))
        return [addCitation, addTemplate, makeBold, makeItalic]
    }()


    lazy var availableMenuActions: [Selector] = {
        let actions = [
            #selector(SectionEditorWebView.cut(_:)),
            #selector(SectionEditorWebView.copy(_:)),
            #selector(SectionEditorWebView.paste(_:)),
            #selector(SectionEditorWebView.select(_:)),
            #selector(SectionEditorWebView.selectAll(_:)),
            #selector(SectionEditorWebView.toggleBoldface(menuItem:)),
            #selector(SectionEditorWebView.toggleItalics(menuItem:)),
            #selector(SectionEditorWebView.toggleCitation(menuItem:)),
            #selector(SectionEditorWebView.toggleLink(menuItem:)),
            #selector(SectionEditorWebView.toggleTemplate(menuItem:))
        ]
        return actions
    }()
}

extension SectionEditorMenuItemsController: SectionEditorMenuItemsDelegate {
    func sectionEditorWebViewDidTapSelectAll(_ sectionEditorWebView: SectionEditorWebView) {
        messagingController.selectAllText()
    }

    func sectionEditorWebViewDidTapBoldface(_ sectionEditorWebView: SectionEditorWebView) {
        messagingController.toggleBoldSelection()
    }

    func sectionEditorWebViewDidTapItalics(_ sectionEditorWebView: SectionEditorWebView) {
        messagingController.toggleItalicSelection()
    }

    func sectionEditorWebViewDidTapCitation(_ sectionEditorWebView: SectionEditorWebView) {
        messagingController.toggleReferenceSelection()
    }

    func sectionEditorWebViewDidTapLink(_ sectionEditorWebView: SectionEditorWebView) {
        delegate?.sectionEditorMenuItemsControllerDidTapLink(self)
    }

    func sectionEditorWebViewDidTapTemplate(_ sectionEditorWebView: SectionEditorWebView) {
        messagingController.toggleTemplateSelection()
    }
}
