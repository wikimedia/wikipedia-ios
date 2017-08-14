import Foundation

@objc(WMFArticleListTableViewRowActions)
class ArticleListTableViewRowActions: NSObject {
    
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
        return self.rowAction(with: UITableViewRowActionStyle.destructive, title: deleteActionText, tableView: tableView, handler: {(_ action: UITableViewRowAction, _ indexPath: IndexPath) -> Void in
            delete(indexPath)
        })
    }
    
    func shareAction(at indexPath: IndexPath, tableView: UITableView, share: @escaping (IndexPath) -> Void) -> UITableViewRowAction {
        return self.rowAction(with: UITableViewRowActionStyle.normal, title: shareActionText, tableView: tableView, handler: {(_ action: UITableViewRowAction, _ indexPath: IndexPath) -> Void in
            share(indexPath)
        })
    }
    
    func saveAction(at indexPath: IndexPath, tableView: UITableView, save: @escaping (IndexPath) -> Void) -> UITableViewRowAction {
        return self.rowAction(with: UITableViewRowActionStyle.normal, title: CommonStrings.shortSaveTitle, tableView: tableView, handler: {(_ action: UITableViewRowAction, _ indexPath: IndexPath) -> Void in
            save(indexPath)
        })
    }
    
    func unsaveAction(at indexPath: IndexPath, tableView: UITableView, unsave: @escaping (IndexPath) -> Void) -> UITableViewRowAction {
        return self.rowAction(with: UITableViewRowActionStyle.normal, title: CommonStrings.shortUnsaveTitle, tableView: tableView, handler: {(_ action: UITableViewRowAction, _ indexPath: IndexPath) -> Void in
            unsave(indexPath)
        })
    }
    
}
