import UIKit

@objc(WMFAddArticleToReadingListToolbarViewControllerDelegate)
public protocol AddArticleToReadingListToolbarViewControllerDelegate: NSObjectProtocol {
    func viewControllerWillBeDismissed()
    func addedArticle(to readingList: ReadingList)
}

@objc(WMFAddArticleToReadingListToolbarViewController)
class AddArticleToReadingListToolbarViewController: UIViewController {
    
    fileprivate let dataStore: MWKDataStore
    fileprivate var theme: Theme = Theme.standard
    
    @objc var article: WMFArticle? {
        didSet {
            let articleTitle = article?.displayTitle ?? "article"
            button.setTitle("Add \(articleTitle) to reading list", for: .normal)
        }
    }
    
    @objc public init(dataStore: MWKDataStore) {
        self.dataStore = dataStore
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    fileprivate var button: AlignedImageButton = AlignedImageButton()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(button)
        button.titleLabel?.lineBreakMode = .byTruncatingTail
        button.verticalPadding = 5
        button.setImage(UIImage(named: "add-to-list"), for: .normal)
        button.addTarget(self, action: #selector(buttonPressed), for: .touchUpInside)
        button.sizeToFit()
        button.translatesAutoresizingMaskIntoConstraints = false
        let centerConstraint = button.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        let leadingConstraint = button.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12)
        let trailingConstraint = view.trailingAnchor.constraint(greaterThanOrEqualTo: button.trailingAnchor, constant: 12)
        centerConstraint.isActive = true
        leadingConstraint.isActive = true
        trailingConstraint.isActive = true
        apply(theme: theme)
    }
    
    @objc func reset() {
        let articleTitle = article?.displayTitle ?? "article"
        button.setTitle("Add \(articleTitle) to reading list", for: .normal)
        button.setImage(UIImage(named: "add-to-list"), for: .normal)
        button.addTarget(self, action: #selector(buttonPressed), for: .touchUpInside)
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        button.titleLabel?.setFont(with: .systemMedium, style: .subheadline, traitCollection: traitCollection)
    }
    
    @objc public weak var delegate: AddArticleToReadingListToolbarViewControllerDelegate?
    
    @objc fileprivate func buttonPressed() {
        guard let article = article else {
            return
        }
        let addArticlesToReadingListViewController = AddArticlesToReadingListViewController(with: dataStore, articles: [article], theme: theme)
        addArticlesToReadingListViewController.delegate = self
        present(addArticlesToReadingListViewController, animated: true, completion: nil)
    }

}

extension AddArticleToReadingListToolbarViewController: AddArticlesToReadingListDelegate {
    func viewControllerWillBeDismissed() {
        delegate?.viewControllerWillBeDismissed()
    }
    
    func addedArticle(to readingList: ReadingList) {
        guard let name = readingList.isDefaultList ? CommonStrings.shortSavedTitle : readingList.name else {
            return
        }
        button.setTitle("Article added to \(name)", for: .normal)
        button.setImage(nil, for: .normal)
        button.removeTarget(self, action: #selector(buttonPressed), for: .touchUpInside)
        delegate?.addedArticle(to: readingList)
    }
}

extension AddArticleToReadingListToolbarViewController: Themeable {
    func apply(theme: Theme) {
        self.theme = theme
        guard viewIfLoaded != nil else {
            return
        }
        view.backgroundColor = theme.colors.disabledLink
        button.setTitleColor(theme.colors.link, for: .normal)
    }
}
