@objc public protocol WMFReadingListActionSheetControllerDelegate: NSObjectProtocol {
    func shouldUnsave(article: WMFArticle)
}

@objc (WMFReadingListActionSheetController)
public class ReadingListActionSheetController: NSObject {
    private let dataStore: MWKDataStore
    private let presenter: UIViewController
    @objc public weak var delegate: WMFReadingListActionSheetControllerDelegate?
    
    @objc init(dataStore: MWKDataStore, presenter: UIViewController) {
        self.dataStore = dataStore
        self.presenter = presenter
    }
    
    @objc  func showActionSheet(for article: WMFArticle, with theme: Theme) {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        let readingListActionTitle = article.isInDefaultList ? WMFLocalizedString("add-to-reading-list", value: "Add to a reading list", comment: "Title of the action that adds a selected article to a reading list") : WMFLocalizedString("move-to-reading-list", value: "Move to a reading list", comment: "Title of the action that moves a selected article to a reading list")
        let unsaveActionTitle = article.isInDefaultList ? WMFLocalizedString("unsave-article", value: "Unsave article", comment: "Title of the action that unsaves a selected article") : String.localizedStringWithFormat(WMFLocalizedString("unsave-article-and-remove-from-reading-lists", value: "Unsave and remove from %1$@", comment: "Title of the action that unsaves a selected article and removes it from all reading lists"), "\(String.localizedStringWithFormat(CommonStrings.readingListCountFormat, article.readingLists?.count ?? 0))")
        let readingListActionTitle = WMFLocalizedString("add-to-reading-list", value: "Add to a reading list", comment: "Title of the action that adds a selected article to a reading list") //article.isInDefaultList ? WMFLocalizedString("add-to-reading-list", value: "Add to a reading list", comment: "Title of the action that adds a selected article to a reading list") //: WMFLocalizedString("move-to-reading-list", value: "Move to a reading list", comment: "Title of the action that moves a selected article to a reading list")
        let unsaveActionTitle = (article.readingLists ?? []).count == 1 && article.isInDefaultList ? WMFLocalizedString("unsave-article", value: "Unsave article", comment: "Title of the action that unsaves a selected article") : String.localizedStringWithFormat(WMFLocalizedString("unsave-article-and-remove-from-reading-lists", value: "Unsave and remove from %1$@", comment: "Title of the action that unsaves a selected article and removes it from all reading lists"), "\(String.localizedStringWithFormat(CommonStrings.readingListCountFormat, article.readingLists?.count ?? 0))")
        
        let readingListAction = UIAlertAction(title: readingListActionTitle, style: .default) { (action) in
            let addArticlesToReadingListViewController = AddArticlesToReadingListViewController(with: self.dataStore, articles: [article], theme: theme)
            self.presenter.present(addArticlesToReadingListViewController, animated: true, completion: nil)
        }
        let unsaveAction = UIAlertAction(title: unsaveActionTitle, style: .destructive) { (actions) in
            self.delegate?.shouldUnsave(article: article)
        }
        let cancel = UIAlertAction(title: CommonStrings.cancelActionTitle, style: .cancel) { (actions) in
            self.presenter.dismiss(animated: true, completion: nil)
        }
        alert.addAction(readingListAction)
        alert.addAction(unsaveAction)
        alert.addAction(cancel)
        presenter.present(alert, animated: true, completion: nil)
    }
}
