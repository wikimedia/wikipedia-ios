class ReadingListHintViewController: UIViewController {
    
    var dataStore: MWKDataStore?
    fileprivate var theme: Theme = Theme.standard
    
    var article: WMFArticle? {
        didSet {
            guard article != oldValue else {
                return
            }
            hintButton?.setTitle("Add \(articleTitle) to reading list", for: .normal)
        }
    }
    
    private var articleTitle: String {
        return article?.displayTitle ?? "article"
    }
    
    @IBOutlet weak var hintView: UIView!
    @IBOutlet weak var hintButton: AlignedImageButton?
    @IBOutlet weak var confirmationView: UIView!
    @IBOutlet weak var confirmationImageView: UIImageView!
    @IBOutlet weak var confirmationButton: UIButton!
    private var confirmationButtonLeadingConstraint: (toImageView: NSLayoutConstraint?, toView: NSLayoutConstraint?)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        confirmationView.isHidden = true
        confirmationImageView.layer.cornerRadius = 3
        confirmationImageView.clipsToBounds = true
        confirmationButtonLeadingConstraint.toImageView = confirmationButton.leadingAnchor.constraint(equalTo: confirmationImageView.trailingAnchor, constant: 12)
        confirmationButtonLeadingConstraint.toView = confirmationButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12)
        hintButton?.verticalPadding = 5
        hintButton?.setTitle("Add \(articleTitle) to reading list", for: .normal)
        apply(theme: theme)
    }
    
    func reset() {
        hintView.isHidden = false
        confirmationView.isHidden = true
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        hintButton?.titleLabel?.setFont(with: .systemMedium, style: .subheadline, traitCollection: traitCollection)
    }
    
    public weak var delegate: ReadingListHintViewControllerDelegate?
    
    @IBAction func addArticleToReadingList(_ sender: Any) {
        guard let article = article, let dataStore = dataStore else {
            return
        }
        let addArticlesToReadingListViewController = AddArticlesToReadingListViewController(with: dataStore, articles: [article], theme: theme)
        addArticlesToReadingListViewController.delegate = self
        present(addArticlesToReadingListViewController, animated: true, completion: nil)
    }
    
    fileprivate var readingList: ReadingList?
    fileprivate var themeableNavigationController: WMFThemeableNavigationController?
    
    @IBAction func openReadingList() {
        guard let readingList = readingList, let dataStore = dataStore else {
            return
        }
        let viewController = readingList.isDefaultList ? SavedArticlesViewController() : ReadingListDetailViewController(for: readingList, with: dataStore)
        (viewController as? SavedArticlesViewController)?.dataStore = dataStore
        viewController.navigationItem.leftBarButtonItem = UIBarButtonItem.wmf_buttonType(WMFButtonType.X, target: self, action: #selector(dismissReadingListDetailViewController))
        viewController.apply(theme: theme)
        let navigationController = WMFThemeableNavigationController(rootViewController: viewController, theme: theme)
        themeableNavigationController = navigationController
        present(navigationController, animated: true) {
            self.delegate?.readingListHint(self, shouldBeHidden: true)
        }
    }
    
    @objc private func dismissReadingListDetailViewController() {
        themeableNavigationController?.dismiss(animated: true, completion: nil) // can this be dismissed in a different way?
    }
    
}

extension ReadingListHintViewController: AddArticlesToReadingListDelegate {
    func addArticlesToReadingList(_ addArticlesToReadingList: AddArticlesToReadingListViewController, didAddArticles articles: [WMFArticle], to readingList: ReadingList) {
        guard let name = readingList.isDefaultList ? CommonStrings.shortSavedTitle : readingList.name else {
            return
        }
        if let imageURL = articles.first?.imageURL(forWidth: traitCollection.wmf_nearbyThumbnailWidth) {
            confirmationButtonLeadingConstraint.toImageView?.isActive = true
            confirmationButtonLeadingConstraint.toView?.isActive = false
            confirmationImageView.wmf_setImage(with: imageURL, detectFaces: true, onGPU: true, failure: { (error) in }, success: { })
        } else {
            confirmationImageView.isHidden = true
            confirmationButtonLeadingConstraint.toImageView?.isActive = false
            confirmationButtonLeadingConstraint.toView?.isActive = true
        }
        self.readingList = readingList
        hintView.isHidden = true
        confirmationView.isHidden = false
        confirmationButton.setTitle("Article added to \(name)", for: .normal)
        delegate?.readingListHint(self, shouldBeHidden: false)
    }
    
    func addArticlesToReadingList(_ addArticlesToReadingList: AddArticlesToReadingListViewController, willBeDismissed: Bool) {
        delegate?.readingListHint(self, shouldBeHidden: willBeDismissed)
    }
}

extension ReadingListHintViewController: Themeable {
    func apply(theme: Theme) {
        self.theme = theme
        guard viewIfLoaded != nil else {
            return
        }
        view.backgroundColor = theme.colors.disabledLink
        hintButton?.setTitleColor(theme.colors.link, for: .normal)
        confirmationButton.setTitleColor(theme.colors.link, for: .normal)
    }
}
