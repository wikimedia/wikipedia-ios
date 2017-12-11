import UIKit

public protocol AddArticleToReadingListToolbarViewControllerDelegate: NSObjectProtocol {
    func addArticlesToReadingListViewControllerWillBeDismissed()
}

class AddArticleToReadingListToolbarViewController: UIViewController {
    
    var dataStore: MWKDataStore?
    var article: WMFArticle? {
        didSet {
            let articleTitle = article?.displayTitle ?? "article"
            button?.setTitle("Add \(articleTitle) to reading list", for: .normal)
        }
    }
    
    fileprivate var button: AlignedImageButton?
    fileprivate var theme: Theme = Theme.standard
    
    func setup(dataStore: MWKDataStore, article: WMFArticle) {
        self.dataStore = dataStore
        self.article = article
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        button = AlignedImageButton()
        apply(theme: theme)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        guard let button = button else {
            return
        }
        view.addSubview(button)
        button.titleLabel?.lineBreakMode = .byTruncatingTail
        button.titleLabel?.setFont(with: .systemMedium, style: .subheadline, traitCollection: traitCollection)
        button.verticalPadding = 5
        button.setImage(UIImage(named: "add"), for: .normal)
        button.addTarget(self, action: #selector(buttonPressed), for: .touchUpInside)
        button.sizeToFit()
        button.translatesAutoresizingMaskIntoConstraints = false
        let centerConstraint = button.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        let leadingConstraint = button.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12)
        centerConstraint.isActive = true
        leadingConstraint.isActive = true
    }
    
    public weak var delegate: AddArticleToReadingListToolbarViewControllerDelegate?
    
    @objc fileprivate func buttonPressed() {
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
        button?.setTitleColor(theme.colors.link, for: .normal)
    }
}
