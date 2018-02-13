@objc public protocol WMFReadingListAlertControllerDelegate: NSObjectProtocol {
    func readingListAlertController(_ readingListAlertController: ReadingListAlertController, didSelectUnsaveForArticle: WMFArticle)
}

@objc (WMFReadingListAlertController)
public class ReadingListAlertController: NSObject {
    private let dataStore: MWKDataStore
    private weak var presenter: UIViewController?
    @objc public weak var delegate: WMFReadingListAlertControllerDelegate?
    
    @objc init(dataStore: MWKDataStore, presenter: UIViewController) {
        self.dataStore = dataStore
        self.presenter = presenter
    }
    
    @objc  func showAlert(for article: WMFArticle) {
        
        guard let readingListsCount = article.readingLists?.count else {
            return
        }
        
        let alert = UIAlertController(title: WMFLocalizedString("unsave-article-and-remove-from-reading-lists-title", value: "Unsave article and remove it from lists?", comment: "Title of the alert action that unsaves a selected article and removes it from all reading lists"), message: String.localizedStringWithFormat(WMFLocalizedString("unsave-article-and-remove-from-reading-lists-message", value: "Unsaving this article will remove it from %1$d reading lists", comment: "Message of the alert action that unsaves a selected article and removes it from all reading lists"), readingListsCount), preferredStyle: .alert)

        let unsaveAction = UIAlertAction(title: CommonStrings.shortUnsaveTitle, style: .destructive) { (actions) in
            self.delegate?.readingListAlertController(self, didSelectUnsaveForArticle: article)
        }
        alert.addAction(unsaveAction)
        
        let cancel = UIAlertAction(title: CommonStrings.cancelActionTitle, style: .cancel, handler: nil)
        alert.addAction(cancel)
        
        presenter?.present(alert, animated: true, completion: nil)
    }
}
