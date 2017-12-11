import UIKit

public protocol AddArticleToReadingListToolbarViewControllerDelegate: NSObjectProtocol {
    func addArticlesToReadingListViewControllerWillBeDismissed()
}

class AddArticleToReadingListToolbarViewController: UIViewController {

    
    @IBOutlet weak var button: AlignedImageButton!
    
    var dataStore: MWKDataStore?
    var article: WMFArticle?
    
    fileprivate var theme: Theme = Theme.standard
    
    func setup(dataStore: MWKDataStore, article: WMFArticle) {
        self.dataStore = dataStore
        self.article = article
        button.setTitle("Add \(article.displayTitle!) to reading list", for: .normal)
        button.setImage(UIImage(named: "add"), for: .normal)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        apply(theme: theme)
    }
    
    public weak var delegate: AddArticleToReadingListToolbarViewControllerDelegate?
    
    @IBAction fileprivate func buttonPressed() {
        guard let dataStore = dataStore, let article = article else {
            return
        }
        let addArticlesToReadingListViewController = AddArticlesToReadingListViewController(with: dataStore, articles: [article], theme: theme)
        addArticlesToReadingListViewController.delegate = self
        present(addArticlesToReadingListViewController, animated: true, completion: nil)
    }

}

extension AddArticleToReadingListToolbarViewController: AddArticlesToReadingListViewControllerDelegate {
    func addArticlesToReadingListViewControllerWillBeDismissed() {
        delegate?.addArticlesToReadingListViewControllerWillBeDismissed()
    }
}

extension AddArticleToReadingListToolbarViewController: Themeable {
    func apply(theme: Theme) {
        self.theme = theme
        guard viewIfLoaded != nil else {
            return
        }
        view.backgroundColor = theme.colors.disabledLink
        button.titleLabel?.textColor = theme.colors.link
    }
}
