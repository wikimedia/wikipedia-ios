class ReadingListHintViewController: UIViewController {
    
    var dataStore: MWKDataStore?
    fileprivate var theme: Theme = Theme.standard
    
    var article: WMFArticle? {
        didSet {
            guard article != oldValue else {
                return
            }
            setHintButtonTitle()
        }
    }
    
    private var hintButtonTitle: String {
        let articleTitle = article?.displayTitle ?? "article"
        return String.localizedStringWithFormat(WMFLocalizedString("reading-list-add-hint-title", value: "Add “%1$@” to a reading list?", comment: "Title of the reading list hint that appears after an article is saved"), "\(articleTitle)")
    }
    
    @IBOutlet weak var hintView: UIView?
    @IBOutlet weak var hintButton: AlignedImageButton?
    @IBOutlet weak var confirmationView: UIView?
    @IBOutlet weak var confirmationImageView: UIImageView!
    @IBOutlet weak var confirmationButton: UIButton!
    @IBOutlet weak var confirmationChevron: UIButton!
    private var confirmationButtonLeadingConstraint: (toImageView: NSLayoutConstraint?, toView: NSLayoutConstraint?)
    
    private var isConfirmationImageViewHidden: Bool = false {
        didSet {
            confirmationImageView.isHidden = isConfirmationImageViewHidden
            confirmationButtonLeadingConstraint.toImageView?.isActive = !isConfirmationImageViewHidden
            confirmationButtonLeadingConstraint.toView?.isActive = isConfirmationImageViewHidden
            view.setNeedsLayout()
        }
    }
    
    private var isHintViewHidden: Bool = false {
        didSet {
            hintView?.isHidden = isHintViewHidden
            confirmationView?.isHidden = !isHintViewHidden
        }
    }
    
    private var tapHintGestureRecognizer: UIGestureRecognizer?
    private var tapConfirmationGestureRecognizer: UIGestureRecognizer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        isHintViewHidden = false
        
        tapHintGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(addArticleToReadingList(_:)))
        tapConfirmationGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(openReadingList))
        if let tapHintGestureRecognizer = tapHintGestureRecognizer {
            hintView?.addGestureRecognizer(tapHintGestureRecognizer)
        }
        if let tapConfirmationGestureRecognizer = tapConfirmationGestureRecognizer {
            confirmationView?.addGestureRecognizer(tapConfirmationGestureRecognizer)
        }
        
        confirmationImageView.layer.cornerRadius = 3
        confirmationImageView.clipsToBounds = true
        confirmationButtonLeadingConstraint.toImageView = confirmationButton.leadingAnchor.constraint(equalTo: confirmationImageView.trailingAnchor, constant: 12)
        confirmationButtonLeadingConstraint.toView = confirmationButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12)
        hintButton?.verticalPadding = 5
        hintButton?.titleLabel?.wmf_configureToAutoAdjustFontSize()
        confirmationButton?.titleLabel?.wmf_configureToAutoAdjustFontSize()
        setHintButtonTitle()
        apply(theme: theme)
        NotificationCenter.default.addObserver(self, selector: #selector(themeChanged), name: Notification.Name(ReadingThemesControlsViewController.WMFUserDidSelectThemeNotification), object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        delegate?.readingListHint(self, shouldBeHidden: true)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        if let tapHintGestureRecognizer = tapHintGestureRecognizer {
            hintView?.removeGestureRecognizer(tapHintGestureRecognizer)
        }
        if let tapConfirmationGestureRecognizer = tapConfirmationGestureRecognizer {
            confirmationView?.removeGestureRecognizer(tapConfirmationGestureRecognizer)
        }
    }
    
    func reset() {
        isHintViewHidden = false
    }
    
    private func setHintButtonTitle() {
        hintButton?.setTitle(hintButtonTitle, for: .normal)
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        hintButton?.titleLabel?.setFont(with: .systemMedium, style: .subheadline, traitCollection: traitCollection)
        confirmationButton?.titleLabel?.setFont(with: .systemMedium, style: .subheadline, traitCollection: traitCollection)
    }
    
    public weak var delegate: ReadingListHintViewControllerDelegate?
    
    @IBAction func addArticleToReadingList(_ sender: Any) {
        guard let article = article, let dataStore = dataStore else {
            return
        }
        let addArticlesToReadingListViewController = AddArticlesToReadingListViewController(with: dataStore, articles: [article], moveFromReadingList: nil, theme: theme)
        addArticlesToReadingListViewController.delegate = self
        present(addArticlesToReadingListViewController, animated: true, completion: nil)
    }
    
    fileprivate var readingList: ReadingList?
    fileprivate var themeableNavigationController: WMFThemeableNavigationController?
    
    @IBAction func openReadingList() {
        guard let readingList = readingList, let dataStore = dataStore else {
            return
        }
        let readingListDetailViewController = ReadingListDetailViewController(for: readingList, with: dataStore, displayType: .modal)
        readingListDetailViewController.apply(theme: theme)
        let navigationController = WMFThemeableNavigationController(rootViewController: readingListDetailViewController, theme: theme)
        themeableNavigationController = navigationController
        present(navigationController, animated: true) {
            self.delegate?.readingListHint(self, shouldBeHidden: true)
        }
    }
    
    @objc private func dismissReadingListDetailViewController() {
        themeableNavigationController?.dismiss(animated: true, completion: nil) // can this be dismissed in a different way?
    }
    
    @objc func themeChanged(notification: Notification) {
        guard let newTheme = notification.userInfo?[ReadingThemesControlsViewController.WMFUserDidSelectThemeNotificationThemeKey] as? Theme else {
            assertionFailure("Expected theme")
            return
        }
        apply(theme: newTheme)
    }
}

extension ReadingListHintViewController: AddArticlesToReadingListDelegate {
    func addArticlesToReadingList(_ addArticlesToReadingList: AddArticlesToReadingListViewController, didAddArticles articles: [WMFArticle], to readingList: ReadingList) {
        guard let name = readingList.name else {
            return
        }
        if let imageURL = articles.first?.imageURL(forWidth: traitCollection.wmf_nearbyThumbnailWidth) {
            isConfirmationImageViewHidden = false
            confirmationImageView.wmf_setImage(with: imageURL, detectFaces: true, onGPU: true, failure: { (error) in }, success: { })
        } else {
            isConfirmationImageViewHidden = true
        }
        self.readingList = readingList
        isHintViewHidden = true
        let title = String.localizedStringWithFormat(WMFLocalizedString("reading-lists-article-added-confirmation", value: "Article added to “%1$@”", comment: "Confirmation shown after the user adds an article to a list"), name)
        confirmationButton.setTitle(title, for: .normal)
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
        view.backgroundColor = theme.colors.hintBackground 
        hintButton?.setTitleColor(theme.colors.link, for: .normal)
        hintButton?.tintColor = theme.colors.link
        confirmationButton.setTitleColor(theme.colors.link, for: .normal)
        confirmationChevron.tintColor = theme.colors.link
    }
}
