import WMFComponents

protocol EditLinkViewControllerDelegate: AnyObject {
    func editLinkViewController(_ editLinkViewController: EditLinkViewController, didTapCloseButton button: UIBarButtonItem)
    func editLinkViewController(_ editLinkViewController: EditLinkViewController, didFinishEditingLink displayText: String?, linkTarget: String)
    func editLinkViewController(_ editLinkViewController: EditLinkViewController, didFailToExtractArticleTitleFromArticleURL articleURL: URL)
    func editLinkViewControllerDidRemoveLink(_ editLinkViewController: EditLinkViewController)
}

class EditLinkViewController: ThemeableViewController, WMFNavigationBarConfiguring {
    weak var delegate: EditLinkViewControllerDelegate?

    private let link: Link
    private let siteURL: URL
    private var articleURL: URL

    private let articleCell = ArticleRightAlignedImageCollectionViewCell()
    private let dataStore: MWKDataStore

    @IBOutlet private weak var contentView: UIView!
    @IBOutlet private weak var scrollViewTopConstraint: NSLayoutConstraint!
    @IBOutlet private weak var displayTextLabel: UILabel!
    @IBOutlet private weak var displayTextView: UITextView!
    @IBOutlet private weak var displayTextViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet private weak var linkTargetLabel: UILabel!
    @IBOutlet private weak var linkTargetContainerView: UIView!
    @IBOutlet private weak var linkTargetContainerViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet private weak var activityIndicatorView: UIActivityIndicatorView!
    @IBOutlet private weak var removeLinkButton: AutoLayoutSafeMultiLineButton!
    @IBOutlet private var separatorViews: [UIView] = []
    
    private lazy var finishEditingButton = UIBarButtonItem(title: CommonStrings.surveySubmitActionTitle, style: .done, target: self, action: #selector(finishEditing(_:)))


    init?(link: Link, siteURL: URL?, dataStore: MWKDataStore, theme: Theme) {
        guard
            let siteURL = siteURL ?? MWKDataStore.shared().primarySiteURL ?? NSURL.wmf_URLWithDefaultSiteAndCurrentLocale(),
            let articleURL = link.articleURL(for: siteURL)
        else {
            return nil
        }
        self.link = link
        self.siteURL = siteURL
        self.articleURL = articleURL
        self.dataStore = dataStore
        super.init(nibName: "EditLinkViewController", bundle: nil)
        self.theme = theme
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        var textContainerInset = displayTextView.textContainerInset
        textContainerInset.top = 15
        displayTextLabel.text = WMFLocalizedString("edit-link-display-text-title", value: "Display text", comment: "Title for the display text label")
        displayTextView.textContainerInset = textContainerInset
        displayTextView.textContainer.lineFragmentPadding = 0
        displayTextView.text = link.label ?? link.page
        linkTargetLabel.text = WMFLocalizedString("edit-link-link-target-title", value: "Link target", comment: "Title for the link target label")
        removeLinkButton.setTitle(WMFLocalizedString("edit-link-remove-link-title", value: "Remove link", comment: "Title for the remove link button"), for: .normal)
        articleCell.isHidden = true
        linkTargetContainerView.addSubview(articleCell)
        updateFonts()
        apply(theme: theme)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        fetchArticle()
        configureNavigationBar()
    }
    
    private func configureNavigationBar() {
        
        let titleConfig = WMFNavigationBarTitleConfig(title: CommonStrings.editLinkTitle, customView: nil, alignment: .centerCompact)
        let closeButtonConfig = WMFNavigationBarCloseButtonConfig(text: CommonStrings.cancelActionTitle, target: self, action: #selector(close(_:)), alignment: .leading)
        
        configureNavigationBar(titleConfig: titleConfig, closeButtonConfig: closeButtonConfig, profileButtonConfig: nil, tabsButtonConfig: nil, searchBarConfig: nil, hideNavigationBarOnScroll: false)
        
        navigationItem.rightBarButtonItem = finishEditingButton
    }

    private func fetchArticle() {
        guard let article = dataStore.fetchArticle(with: articleURL) else {
            guard let key = articleURL.wmf_inMemoryKey else {
                return
            }
            dataStore.articleSummaryController.updateOrCreateArticleSummaryForArticle(withKey: key) { (article, _) in
                guard let article = article else {
                    return
                }
                self.updateView(with: article)
            }
            return
        }
        updateView(with: article)
    }

    private func updateView(with article: WMFArticle) {
        articleCell.configure(article: article, displayType: .compactList, index: 0, theme: theme, layoutOnly: false)
        articleCell.topSeparator.isHidden = true
        articleCell.bottomSeparator.isHidden = true
        articleCell.extractLabel?.numberOfLines = 5
        updateLinkTargetContainer()
        articleCell.isHidden = false

        activityIndicatorView.stopAnimating()
        view.setNeedsLayout()
    }

    private func updateLinkTargetContainer() {
        articleCell.frame = CGRect(origin: linkTargetContainerView.bounds.origin, size: articleCell.sizeThatFits(CGSize(width: linkTargetContainerView.bounds.width, height: UIView.noIntrinsicMetric), apply: true))
        linkTargetContainerViewHeightConstraint.constant = articleCell.frame.height
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        updateFonts()
    }

    private func updateFonts() {
        displayTextLabel.font = WMFFont.for(.footnote, compatibleWith: traitCollection)
        linkTargetLabel.font = WMFFont.for(.footnote, compatibleWith: traitCollection)
        displayTextView.font = WMFFont.for(.subheadline, compatibleWith: traitCollection)
        removeLinkButton.titleLabel?.font = WMFFont.for(.subheadline, compatibleWith: traitCollection)
    }

    @objc private func close(_ sender: UIBarButtonItem) {
        delegate?.editLinkViewController(self, didTapCloseButton: sender)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        displayTextViewHeightConstraint.constant = displayTextView.sizeThatFits(CGSize(width: displayTextView.bounds.width, height: UIView.noIntrinsicMetric)).height
        updateLinkTargetContainer()
    }

    @objc private func finishEditing(_ sender: UIBarButtonItem) {
        let displayText = displayTextView.text
        guard let linkTarget = articleURL.wmf_title else {
            assertionFailure("Failed to extract article title from url: \(articleURL)")
            delegate?.editLinkViewController(self, didFailToExtractArticleTitleFromArticleURL: articleURL)
            return
        }
        delegate?.editLinkViewController(self, didFinishEditingLink: displayText, linkTarget: linkTarget)
    }

    @IBAction private func removeLink(_ sender: UIButton) {
        delegate?.editLinkViewControllerDidRemoveLink(self)
    }

    @IBAction private func searchArticles(_ sender: UITapGestureRecognizer) {
        let searchViewController = SearchViewController(source: .unknown)
        searchViewController.siteURL = siteURL
        searchViewController.shouldBecomeFirstResponder = true
        searchViewController.dataStore = MWKDataStore.shared()
        
        let navigateToSearchResultAction: ((URL) -> Void) = { [weak self] articleURL in
            guard let self else {
                return
            }
            self.articleURL = articleURL
            navigationController?.popViewController(animated: true)
        }
        
        searchViewController.navigateToSearchResultAction = navigateToSearchResultAction
        searchViewController.showLanguageBar = false
        searchViewController.customTitle = CommonStrings.editLinkTitle
        searchViewController.needsCenteredTitle = true
        searchViewController.searchTerm = articleURL.wmf_title
        searchViewController.search()
        searchViewController.theme = theme
        searchViewController.apply(theme: theme)
        navigationController?.pushViewController(searchViewController, animated: true)
    }

    override func apply(theme: Theme) {
        super.apply(theme: theme)
        self.theme = theme
        guard viewIfLoaded != nil else {
            return
        }
        contentView.backgroundColor = theme.colors.paperBackground
        view.backgroundColor = theme.colors.baseBackground
        separatorViews.forEach { $0.backgroundColor = theme.colors.border }
        displayTextLabel.textColor = theme.colors.secondaryText
        linkTargetLabel.textColor = theme.colors.secondaryText
        removeLinkButton.tintColor = theme.colors.destructive
        removeLinkButton.backgroundColor = theme.colors.paperBackground
        displayTextView.textColor = theme.colors.primaryText
        activityIndicatorView.color = theme.isDark ? .white : .gray
        articleCell.apply(theme: theme)
    }
}
