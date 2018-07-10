class ReadingListHintViewController: UIViewController {
    
    var dataStore: MWKDataStore?
    private var theme: Theme = Theme.standard
    
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
        return String.localizedStringWithFormat(WMFLocalizedString("reading-list-add-hint-title", value: "Add “%1$@” to a reading list?", comment: "Title of the reading list hint that appears after an article is saved. %1$@ will be replaced with the saved article title"), "\(articleTitle)")
    }
    
    @IBOutlet private weak var hintView: UIView?
    @IBOutlet private weak var hintLabel: UILabel?
    @IBOutlet private weak var confirmationContainerView: UIView?
    @IBOutlet private weak var confirmationImageView: UIImageView!
    @IBOutlet private weak var confirmationLabel: UILabel!
    @IBOutlet private weak var confirmationChevron: UIButton!
    @IBOutlet private weak var outerStackView: UIStackView!
    @IBOutlet private weak var confirmationStackView: UIStackView!

    private var isConfirmationImageViewHidden: Bool = false {
        didSet {
            confirmationImageView.isHidden = isConfirmationImageViewHidden
        }
    }
    
    private var isHintViewHidden: Bool = false {
        didSet {
            hintView?.isHidden = isHintViewHidden
            confirmationContainerView?.isHidden = !isHintViewHidden
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        isHintViewHidden = false
        
        confirmationImageView.layer.cornerRadius = 3
        confirmationImageView.clipsToBounds = true
        setHintButtonTitle()
        apply(theme: theme)
        NotificationCenter.default.addObserver(self, selector: #selector(themeChanged), name: Notification.Name(ReadingThemesControlsViewController.WMFUserDidSelectThemeNotification), object: nil)
        
        let chevronImage = view.effectiveUserInterfaceLayoutDirection == .rightToLeft ? UIImage(named: "chevron-left") : UIImage(named: "chevron-right")
        confirmationChevron.setImage(chevronImage, for: .normal)
    
        assert(outerStackView.wmf_firstArrangedSubviewWithRequiredNonZeroHeightConstraint() == nil, outerStackView.wmf_anArrangedSubviewHasRequiredNonZeroHeightConstraintAssertString())
        assert(confirmationStackView.wmf_firstArrangedSubviewWithRequiredNonZeroHeightConstraint() == nil, confirmationStackView.wmf_anArrangedSubviewHasRequiredNonZeroHeightConstraintAssertString())
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        delegate?.readingListHint(self, shouldBeHidden: true)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    func reset() {
        isHintViewHidden = false
    }
    
    private func setHintButtonTitle() {
        hintLabel?.text = hintButtonTitle
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        hintLabel?.font = UIFont.wmf_font(.mediumSubheadline, compatibleWithTraitCollection: traitCollection)
        confirmationLabel?.font = UIFont.wmf_font(.mediumSubheadline, compatibleWithTraitCollection: traitCollection)
    }
    
    private var previousHeight:CGFloat = 0.0
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if previousHeight != view.frame.size.height {
            delegate?.readingListHintHeightChanged()
        }
        previousHeight = view.frame.size.height
    }
    
    public weak var delegate: ReadingListHintViewControllerDelegate?
    
    @IBAction func addArticleToReadingList(_ sender: Any) {
        guard let article = article, let dataStore = dataStore else {
            return
        }
        let addArticlesToReadingListViewController = AddArticlesToReadingListViewController(with: dataStore, articles: [article], moveFromReadingList: nil, theme: theme)
        addArticlesToReadingListViewController.delegate = self
        let navigationController = WMFThemeableNavigationController(rootViewController: addArticlesToReadingListViewController, theme: theme)
        navigationController.isNavigationBarHidden = true
        present(navigationController, animated: true)
    }
    
    private var readingList: ReadingList?
    private var themeableNavigationController: WMFThemeableNavigationController?
    
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
        themeableNavigationController?.dismiss(animated: true) // can this be dismissed in a different way?
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
        let title = String.localizedStringWithFormat(WMFLocalizedString("reading-lists-article-added-confirmation", value: "Article added to “%1$@”", comment: "Confirmation shown after the user adds an article to a list. %1$@ will be replaced with the name of the list the article was added to."), name)
        confirmationLabel.text = title
        isHintViewHidden = true
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
        hintLabel?.textColor = theme.colors.link
        hintLabel?.tintColor = theme.colors.link
        confirmationLabel?.textColor = theme.colors.link        
        confirmationChevron.tintColor = theme.colors.link
    }
}
