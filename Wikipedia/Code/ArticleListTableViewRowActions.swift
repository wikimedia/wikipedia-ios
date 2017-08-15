import Foundation

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
    
    func deleteAction(at indexPath: IndexPath, tableView: UITableView, delete: @escaping (IndexPath) -> Void) -> UITableViewRowAction {
        let action = rowAction(with: UITableViewRowActionStyle.destructive, title: deleteActionText, tableView: tableView, handler: {(_ action: UITableViewRowAction, _ indexPath: IndexPath) -> Void in
            delete(indexPath)
        })
        action.backgroundColor = self.theme.colors.destructive
        return action
    }
    
    func shareAction(at indexPath: IndexPath, tableView: UITableView, share: @escaping (IndexPath) -> Void) -> UITableViewRowAction {
        let action = rowAction(with: UITableViewRowActionStyle.normal, title: shareActionText, tableView: tableView, handler: {(_ action: UITableViewRowAction, _ indexPath: IndexPath) -> Void in
            share(indexPath)
        })
        action.backgroundColor = self.theme.colors.secondaryAction
        return action
    }
    
    func saveAction(at indexPath: IndexPath, tableView: UITableView, save: @escaping (IndexPath) -> Void) -> UITableViewRowAction {
        let action = rowAction(with: UITableViewRowActionStyle.normal, title: CommonStrings.shortSaveTitle, tableView: tableView, handler: {(_ action: UITableViewRowAction, _ indexPath: IndexPath) -> Void in
            save(indexPath)
        })
        action.backgroundColor = self.theme.colors.link
        return action
    }
    
    func unsaveAction(at indexPath: IndexPath, tableView: UITableView, unsave: @escaping (IndexPath) -> Void) -> UITableViewRowAction {
        let action = rowAction(with: UITableViewRowActionStyle.normal, title: CommonStrings.shortUnsaveTitle, tableView: tableView, handler: {(_ action: UITableViewRowAction, _ indexPath: IndexPath) -> Void in
            unsave(indexPath)
        })
        action.backgroundColor = self.theme.colors.link
        return action
    }
    
    func allActions(at indexPath: IndexPath, tableView: UITableView, delete: @escaping ((IndexPath) -> Void), share: @escaping((IndexPath) -> Void), unsave: @escaping ((IndexPath) -> Void), save: @escaping ((IndexPath) -> Void), isItemSaved: Bool) -> [UITableViewRowAction] {
        var actions = [UITableViewRowAction]()
        let delete = deleteAction(at: indexPath, tableView: tableView, delete: delete)
        let share = shareAction(at: indexPath, tableView: tableView, share: share)
        let unsave = unsaveAction(at: indexPath, tableView: tableView, unsave: unsave)
        let save = saveAction(at: indexPath, tableView: tableView, save: save)
        actions.append(delete)
        actions.append(share)
        isItemSaved ? actions.append(unsave) : actions.append(save)
        return actions
    }
    
}

extension ArticleListTableViewRowActions: Themeable {
    public func apply(theme: Theme) {
        self.theme = theme
    }
}
