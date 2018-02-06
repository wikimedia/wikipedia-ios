@objc public protocol WMFReadingListActionSheetControllerDelegate: NSObjectProtocol {
    func readingListActionSheetController(_ readingListActionSheetController: ReadingListActionSheetController, didSelectUnsaveForArticle: WMFArticle)
}

@objc (WMFReadingListActionSheetController)
public class ReadingListActionSheetController: NSObject {
    private let dataStore: MWKDataStore
    private weak var presenter: UIViewController?
    @objc public weak var delegate: WMFReadingListActionSheetControllerDelegate?
    
    @objc init(dataStore: MWKDataStore, presenter: UIViewController) {
        self.dataStore = dataStore
        self.presenter = presenter
    }
    
    @objc  func showActionSheet(for article: WMFArticle, with theme: Theme) {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        let readingListActionTitle = !article.isInDefaultList ? WMFLocalizedString("add-to-reading-list", value: "Add to a reading list", comment: "Title of the action that adds a selected article to a reading list") : WMFLocalizedString("move-to-reading-list", value: "Move to a reading list", comment: "Title of the action that moves a selected article to a reading list")
        let unsaveActionTitle = article.isOnlyInDefaultList ? CommonStrings.shortUnsaveTitle : String.localizedStringWithFormat(WMFLocalizedString("unsave-article-and-remove-from-reading-lists", value: "Unsave and remove from {{PLURAL:%1$d|%1$d reading list|%1$d reading lists}}", comment: "Title of the action that unsaves a selected article and removes it from all reading lists"), article.readingLists?.count ?? 0)
        
        let readingListAction = UIAlertAction(title: readingListActionTitle, style: .default) { (action) in
            let addArticlesToReadingListViewController = AddArticlesToReadingListViewController(with: self.dataStore, articles: [article], theme: theme)
            self.presenter?.present(addArticlesToReadingListViewController, animated: true, completion: nil)
        }
        let unsaveAction = UIAlertAction(title: unsaveActionTitle, style: .destructive) { (actions) in
            self.delegate?.readingListActionSheetController(self, didSelectUnsaveForArticle: article)
        }
        let cancel = UIAlertAction(title: CommonStrings.cancelActionTitle, style: .cancel, handler: nil)
        alert.addAction(readingListAction)
        alert.addAction(unsaveAction)
        alert.addAction(cancel)
        presenter?.present(alert, animated: true, completion: nil)
    }
}
