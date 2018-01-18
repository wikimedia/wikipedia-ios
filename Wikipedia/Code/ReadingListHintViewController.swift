class ReadingListHintViewController: UIViewController {
    
    fileprivate let dataStore: MWKDataStore
    fileprivate var theme: Theme = Theme.standard
    
    var article: WMFArticle? {
        didSet {
            let articleTitle = article?.displayTitle ?? "article"
            button.setTitle("Add \(articleTitle) to reading list", for: .normal)
        }
    }
    
    public init(dataStore: MWKDataStore) {
        self.dataStore = dataStore
        super.init(nibName: "ReadingListHintViewController", bundle: nil)
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
        button.addTarget(self, action: #selector(addArticleToReadingList), for: .touchUpInside)
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
    
    func reset() {
        let articleTitle = article?.displayTitle ?? "article"
        button.setTitle("Add \(articleTitle) to reading list", for: .normal)
        button.setImage(UIImage(named: "add-to-list"), for: .normal)
        button.removeTarget(self, action: #selector(openReadingList), for: .touchUpInside)
        button.addTarget(self, action: #selector(addArticleToReadingList), for: .touchUpInside)
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        button.titleLabel?.setFont(with: .systemMedium, style: .subheadline, traitCollection: traitCollection)
    }
    
    public weak var delegate: ReadingListHintViewControllerDelegate?
    
    @objc fileprivate func addArticleToReadingList() {
        guard let article = article else {
            return
        }
        let addArticlesToReadingListViewController = AddArticlesToReadingListViewController(with: dataStore, articles: [article], theme: theme)
        addArticlesToReadingListViewController.delegate = self
        present(addArticlesToReadingListViewController, animated: true, completion: nil)
    }
    
    fileprivate var readingList: ReadingList?
    fileprivate var themeableNavigationController: WMFThemeableNavigationController?
    
    @objc fileprivate func openReadingList() {
        guard let readingList = readingList else {
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
        self.readingList = readingList
        button.setTitle("Article added to \(name)", for: .normal)
        button.setImage(nil, for: .normal)
        button.removeTarget(self, action: #selector(addArticleToReadingList), for: .touchUpInside)
        button.addTarget(self, action: #selector(openReadingList), for: .touchUpInside)
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
        button.setTitleColor(theme.colors.link, for: .normal)
    }
}
