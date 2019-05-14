import UIKit

protocol EditLinkViewControllerDelegate: AnyObject {
    func editLinkViewController(_ editLinkViewController: EditLinkViewController, didTapCloseButton button: UIBarButtonItem)
    func editLinkViewController(_ editLinkViewController: EditLinkViewController, didFinishEditingLink displayText: String?, linkTarget: String)
    func editLinkViewController(_ editLinkViewController: EditLinkViewController, didFailToExtractArticleTitleFromArticleURL articleURL: URL)
    func editLinkViewControllerDidRemoveLink(_ editLinkViewController: EditLinkViewController)
}

class EditLinkViewController: ViewController {
    weak var delegate: EditLinkViewControllerDelegate?

    typealias Link = SectionEditorWebViewMessagingController.Link
    private let link: Link
    private let siteURL: URL
    private var articleURL: URL

    private let articleCell = ArticleRightAlignedImageCollectionViewCell()
    private let dataStore: MWKDataStore

    private var navigationBarVisibleHeightObservation: NSKeyValueObservation?

    @IBOutlet private weak var contentView: UIView!
    @IBOutlet private weak var contentViewTopConstraint: NSLayoutConstraint!
    @IBOutlet private weak var displayTextLabel: UILabel!
    @IBOutlet private weak var displayTextView: UITextView!
    @IBOutlet private weak var displayTextViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet private weak var linkTargetLabel: UILabel!
    @IBOutlet private weak var linkTargetContainerView: UIView!
    @IBOutlet private weak var activityIndicatorView: UIActivityIndicatorView!
    @IBOutlet private weak var removeLinkButton: AutoLayoutSafeMultiLineButton!
    @IBOutlet private var separatorViews: [UIView] = []

    private lazy var closeButton: UIBarButtonItem = {
        let closeButton = UIBarButtonItem.wmf_buttonType(.X, target: self, action: #selector(close(_:)))
        closeButton.accessibilityLabel = CommonStrings.closeButtonAccessibilityLabel
        return closeButton
    }()

    private lazy var doneButton = UIBarButtonItem(title: CommonStrings.doneTitle, style: .done, target: self, action: #selector(finishEditing(_:)))

    init?(link: Link, siteURL: URL?, dataStore: MWKDataStore) {
        guard
            let siteURL = siteURL,
            let articleURL = link.articleURL(for: siteURL)
        else {
            return nil
        }
        self.link = link
        self.siteURL = siteURL
        self.articleURL = articleURL
        self.dataStore = dataStore
        super.init(nibName: "EditLinkViewController", bundle: nil)
    }

    deinit {
        navigationBarVisibleHeightObservation?.invalidate()
        navigationBarVisibleHeightObservation = nil
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationBar.displayType = .modal
        title = CommonStrings.editLinkTitle
        navigationItem.leftBarButtonItem = closeButton
        navigationItem.rightBarButtonItem = doneButton
        navigationItem.backBarButtonItem = UIBarButtonItem(title: CommonStrings.accessibilityBackTitle, style: .plain, target: nil, action: nil)
        var textContainerInset = displayTextView.textContainerInset
        textContainerInset.top = 15
        displayTextView.textContainerInset = textContainerInset
        displayTextView.textContainer.lineFragmentPadding = 0
        displayTextView.text = link.label
        articleCell.isHidden = true
        linkTargetContainerView.addSubview(articleCell)
        navigationBarVisibleHeightObservation = navigationBar.observe(\.visibleHeight, options: [.new, .initial], changeHandler: { [weak self] (observation, change) in
            guard let self = self else {
                return
            }
            self.contentViewTopConstraint.constant = self.navigationBar.visibleHeight
        })
        apply(theme: theme)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        fetchArticle()
    }

    private func fetchArticle() {
        guard let article = dataStore.fetchArticle(with: articleURL) else {
            dataStore.articleSummaryController.updateOrCreateArticleSummariesForArticles(withURLs: [articleURL]) { (articles, _) in
                guard let first = articles.first else {
                    return
                }
                self.updateView(with: first)
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
        articleCell.frame = linkTargetContainerView.bounds
        articleCell.isHidden = false

        activityIndicatorView.stopAnimating()
        view.setNeedsLayout()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        displayTextLabel.font = UIFont.wmf_font(.footnote, compatibleWithTraitCollection: traitCollection)
        linkTargetLabel.font = UIFont.wmf_font(.footnote, compatibleWithTraitCollection: traitCollection)
        displayTextView.font = UIFont.wmf_font(.subheadline, compatibleWithTraitCollection: traitCollection)
        removeLinkButton.titleLabel?.font = UIFont.wmf_font(.subheadline, compatibleWithTraitCollection: traitCollection)
    }

    @objc private func close(_ sender: UIBarButtonItem) {
        delegate?.editLinkViewController(self, didTapCloseButton: sender)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        displayTextViewHeightConstraint.constant = displayTextView.sizeThatFits(CGSize(width: displayTextView.bounds.width, height: UIView.noIntrinsicMetric)).height
        articleCell.frame = linkTargetContainerView.bounds
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
        let searchViewController = SearchViewController()
        searchViewController.shouldSetTitleViewWhenRecentSearchesAreDisabled = false
        searchViewController.shouldSetSearchVisible = false
        searchViewController.shouldBecomeFirstResponder = true
        searchViewController.displayType = .backVisible
        searchViewController.areRecentSearchesEnabled = false
        searchViewController.dataStore = SessionSingleton.sharedInstance()?.dataStore
        searchViewController.shouldShowCancelButton = false
        searchViewController.delegate = self
        searchViewController.delegatesSelection = true
        searchViewController.showLanguageBar = false
        searchViewController.navigationItem.title = title
        searchViewController.searchTerm = articleURL.wmf_title
        searchViewController.search()
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
        closeButton.tintColor = theme.colors.primaryText
        doneButton.tintColor = theme.colors.link
        displayTextView.textColor = theme.colors.primaryText
        activityIndicatorView.style = theme.isDark ? .white : .gray
    }
}

extension EditLinkViewController: ArticleCollectionViewControllerDelegate {
    func articleCollectionViewController(_ articleCollectionViewController: ArticleCollectionViewController, didSelectArticleWith articleURL: URL, at indexPath: IndexPath) {
        self.articleURL = articleURL
    }
}
