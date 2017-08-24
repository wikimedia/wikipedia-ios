import Foundation

// When objects using row actions are in Swift, use associated types in this enum. E.g., case delete(IndexPath -> Void).
@objc enum ArticleListTableViewRowActionType: Int {
    case delete
    case share
    case unsave
    case save
}

@objc(WMFArticleListTableViewRowActions)
class ArticleListTableViewRowActions: NSObject {
    
    fileprivate var theme = Theme.standard
    
    let deleteActionText = WMFLocalizedStringWithDefaultValue("article-delete", nil, nil, "Delete", "Text of the article list row action shown on swipe which deletes the article")
    let shareActionText = WMFLocalizedStringWithDefaultValue("article-share", nil, nil, "Share", "Text of the article list row action shown on swipe which allows the user to choose the sharing option")
    
    func rowAction(with style: UITableViewRowActionStyle, title: String, tableView: UITableView, handler: @escaping (UITableViewRowAction, IndexPath) -> Void) -> UITableViewRowAction {
        return UITableViewRowAction(style: style, title: title, handler: {(_ action: UITableViewRowAction, _ indexPath: IndexPath) -> Void in
            CATransaction.begin()
            CATransaction.setCompletionBlock({() -> Void in
                handler(action, indexPath)
            })
            tableView.setEditing(false, animated: true)
            CATransaction.commit()
        })
    }
    
    @objc func action(for type: ArticleListTableViewRowActionType, at indexPath: IndexPath, in tableView: UITableView, perform: @escaping (IndexPath) -> Void) -> UITableViewRowAction {
        
        let backgroundColor: UIColor
        let title: String
        
        switch type {
        case .delete:
            title = deleteActionText
            backgroundColor = self.theme.colors.destructive
        case .save:
            title = CommonStrings.shortSaveTitle
            backgroundColor = self.theme.colors.link
        case .unsave:
            title = CommonStrings.shortUnsaveTitle
            backgroundColor = self.theme.colors.link
        case .share:
            title = shareActionText
            backgroundColor = self.theme.colors.secondaryAction
        }
        
        let action = rowAction(with: UITableViewRowActionStyle.normal, title: title, tableView: tableView, handler: {(_ action: UITableViewRowAction, _ indexPath: IndexPath) -> Void in
            perform(indexPath)
        })
        action.backgroundColor = backgroundColor
        return action
    }
    
}

extension ArticleListTableViewRowActions: Themeable {
    public func apply(theme: Theme) {
        self.theme = theme
    }
}
