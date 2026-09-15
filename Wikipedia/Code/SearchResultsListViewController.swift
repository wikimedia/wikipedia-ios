import UIKit
import WMF
import WMFComponents
import WMFNativeLocalizations

class SearchResultsListViewController: ArticleCollectionViewController {
    var resultsInfo: WMFSearchResults? = nil // don't use resultsInfo.results, it mutates
    var results: [MWKSearchResult] = [] {
        didSet {
            assert(Thread.isMainThread)
            reload()
        }
    }
    var tappedSearchResultAction: ((URL, IndexPath) -> Void)?
    var longPressSearchResultAndCommitAction: ((URL) -> Void)?
    var longPressOpenInNewTabAction: ((URL) -> Void)?

    /// PROTOTYPE: called when the semantic search "Find" cell at the top of the results is tapped.
    var tappedFindAction: (() -> Void)?

    override func viewDidLoad() {
        super.viewDidLoad()
        layoutManager.register(SearchFindCollectionViewCell.self, forCellWithReuseIdentifier: SearchFindCollectionViewCell.identifier, addPlaceholder: false)
        reload()
        NotificationCenter.default.addObserver(self, selector: #selector(updateArticleCell(_:)), name: NSNotification.Name.WMFArticleUpdated, object: nil)
    }

    // MARK: - PROTOTYPE: Find cell

    /// The "Find" cell occupies item 0 whenever there are results, so every article lookup is
    /// offset by one.
    private var isShowingFindCell: Bool {
        return !results.isEmpty
    }

    private func isFindCell(at indexPath: IndexPath) -> Bool {
        return isShowingFindCell && indexPath.item == 0
    }

    private func resultIndex(for indexPath: IndexPath) -> Int? {
        let index = isShowingFindCell ? indexPath.item - 1 : indexPath.item
        guard results.indices.contains(index) else {
            return nil
        }
        return index
    }

    func reload() {
        collectionView.reloadData()
        updateEmptyState()
    }

    var searchSiteURL: URL? = nil

    func isDisplaying(resultsFor searchTerm: String, from siteURL: URL) -> Bool {
        guard let searchResults = resultsInfo, let searchSiteURL = searchSiteURL else {
            return false
        }
        return !results.isEmpty && (searchSiteURL as NSURL).wmf_isEqual(toIgnoringScheme: siteURL) && searchResults.searchTerm == searchTerm
    }

    override var eventLoggingCategory: EventCategoryMEP {
        return .search
    }

    override func articleURL(at indexPath: IndexPath) -> URL? {
        guard let index = resultIndex(for: indexPath) else {
            return nil
        }
        return results[index].articleURL(forSiteURL: searchSiteURL)
    }

    override func article(at indexPath: IndexPath) -> WMFArticle? {
        guard let index = resultIndex(for: indexPath),
              let articleURL = articleURL(at: indexPath) else {
            return nil
        }
        let article = dataStore.fetchOrCreateArticle(with: articleURL)
        let result = results[index]
        article?.update(with: result)
        return article
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return isShowingFindCell ? results.count + 1 : results.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard isFindCell(at: indexPath) else {
            return super.collectionView(collectionView, cellForItemAt: indexPath)
        }

        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: SearchFindCollectionViewCell.identifier, for: indexPath)
        guard let findCell = cell as? SearchFindCollectionViewCell else {
            return cell
        }
        findCell.tappedFindAction = { [weak self] in
            self?.tappedFindAction?()
        }
        findCell.apply(theme: theme)
        return findCell
    }

    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if isFindCell(at: indexPath) {
            collectionView.deselectItem(at: indexPath, animated: true)
            tappedFindAction?()
            return
        }

        guard let articleURL = articleURL(at: indexPath) else {
            collectionView.deselectItem(at: indexPath, animated: true)
            return
        }

        tappedSearchResultAction?(articleURL, indexPath)
    }

    override func collectionView(_ collectionView: UICollectionView, estimatedHeightForItemAt indexPath: IndexPath, forColumnWidth columnWidth: CGFloat) -> ColumnarCollectionViewLayoutHeightEstimate {
        guard !isFindCell(at: indexPath) else {
            return ColumnarCollectionViewLayoutHeightEstimate(precalculated: true, height: SearchFindCollectionViewCell.height)
        }
        return super.collectionView(collectionView, estimatedHeightForItemAt: indexPath, forColumnWidth: columnWidth)
    }

    func redirectMappingForSearchResult(_ result: MWKSearchResult) -> MWKSearchRedirectMapping? {
        return resultsInfo?.redirectMappings?.filter({ (mapping) -> Bool in
            return result.displayTitle == mapping.redirectToTitle
        }).first
    }

    func descriptionForSearchResult(_ result: MWKSearchResult) -> String? {
        let capitalizedWikidataDescription = (result.wikidataDescription as NSString?)?.wmf_stringByCapitalizingFirstCharacter(usingWikipediaLanguageCode: searchSiteURL?.wmf_languageCode)
        let mapping = redirectMappingForSearchResult(result)
        guard let redirectFromTitle = mapping?.redirectFromTitle else {
            return capitalizedWikidataDescription
        }

        let redirectFormat = WMFLocalizedString("search-result-redirected-from", value: "Redirected from: %1$@", comment: "Text for search result letting user know if a result is a redirect from another article. Parameters: * %1$@ - article title the current search result redirected from")
        let redirectMessage = String.localizedStringWithFormat(redirectFormat, redirectFromTitle)

        guard let description = capitalizedWikidataDescription else {
            return redirectMessage
        }

        return String.localizedStringWithFormat("%@\n%@", redirectMessage, description)
    }

    override func configure(cell: ArticleRightAlignedImageCollectionViewCell, forItemAt indexPath: IndexPath, layoutOnly: Bool) {
        configure(cell: cell, forItemAt: indexPath, layoutOnly: layoutOnly, configureForCompact: true)
    }

    private func configure(cell: ArticleRightAlignedImageCollectionViewCell, forItemAt indexPath: IndexPath, layoutOnly: Bool, configureForCompact: Bool) {
        guard let index = resultIndex(for: indexPath) else {
            return
        }
        let result = results[index]
        guard let languageCode = searchSiteURL?.wmf_languageCode,
              let contentLanguageCode = searchSiteURL?.wmf_contentLanguageCode else {
            return
        }

        if configureForCompact {
            cell.configureForCompactList(at: index)
        }

        cell.accessibilityIdentifier = AccessibilityIdentifiers.Search.result(result.displayTitle ?? result.title ?? "")
        cell.setTitleHTML(result.displayTitleHTML, boldedString: resultsInfo?.searchTerm)
        cell.articleSemanticContentAttribute = MWKLanguageLinkController.semanticContentAttribute(forContentLanguageCode: contentLanguageCode)
        cell.titleLabel.accessibilityLanguage = languageCode
        cell.descriptionLabel.text = descriptionForSearchResult(result)
        cell.descriptionLabel.accessibilityLanguage = languageCode
        cell.updateAccessibilityElements()
        editController.configureSwipeableCell(cell, forItemAt: indexPath, layoutOnly: layoutOnly)
        if layoutOnly {
            cell.isImageViewHidden = result.thumbnailURL != nil
        } else {
            cell.imageURL = result.thumbnailURL
        }
        cell.apply(theme: theme)
    }

    override func apply(theme: Theme) {
        super.apply(theme: theme)
        guard viewIfLoaded != nil else {
            return
        }
        collectionView.backgroundColor = theme.colors.midBackground
    }

    @objc func updateArticleCell(_ notification: NSNotification) {
        guard let updatedArticle = notification.object as? WMFArticle,
              updatedArticle.hasChangedValuesForCurrentEventThatAffectSavedState,
              let updatedArticleKey = updatedArticle.inMemoryKey else {
            return
        }

        for indexPath in collectionView.indexPathsForVisibleItems {
            guard articleURL(at: indexPath)?.wmf_inMemoryKey == updatedArticleKey,
                  let cell = collectionView.cellForItem(at: indexPath) as? ArticleRightAlignedImageCollectionViewCell else {
                continue
            }

            configure(cell: cell, forItemAt: indexPath, layoutOnly: false, configureForCompact: false)
        }
    }

    override func collectionView(_ collectionView: UICollectionView, willPerformPreviewActionForMenuWith configuration: UIContextMenuConfiguration, animator: UIContextMenuInteractionCommitAnimating) {

        guard let peekVC = animator.previewViewController as? ArticlePeekPreviewViewController else {
            assertionFailure("Should be able to find previewed VC")
            return
        }
        animator.addCompletion { [weak self] in

            guard let self else { return }

            self.longPressSearchResultAndCommitAction?(peekVC.articleURL)
        }
    }

    override func readMoreArticlePreviewActionSelected(with peekController: ArticlePeekPreviewViewController) {

        longPressSearchResultAndCommitAction?(peekController.articleURL)
    }

    override func openInNewTabArticlePreviewActionSelected(with peekController: ArticlePeekPreviewViewController) {
        longPressOpenInNewTabAction?(peekController.articleURL)
    }
}

// MARK: - PROTOTYPE: Find cell

/// Plain cell shown above search results that kicks off a semantic search for the same term.
final class SearchFindCollectionViewCell: UICollectionViewCell {

    static let height: CGFloat = 56

    var tappedFindAction: (() -> Void)?

    private let findButton = UIButton(type: .system)

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        findButton.setTitle("Find", for: .normal)
        findButton.titleLabel?.font = WMFFont.for(.boldCallout)
        findButton.layer.borderWidth = 1
        findButton.layer.cornerRadius = 8
        findButton.addTarget(self, action: #selector(tappedFind), for: .touchUpInside)

        findButton.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(findButton)
        NSLayoutConstraint.activate([
            findButton.leadingAnchor.constraint(equalTo: contentView.readableContentGuide.leadingAnchor),
            findButton.trailingAnchor.constraint(equalTo: contentView.readableContentGuide.trailingAnchor),
            findButton.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            findButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8)
        ])
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        tappedFindAction = nil
    }

    @objc private func tappedFind() {
        tappedFindAction?()
    }

    func apply(theme: Theme) {
        contentView.backgroundColor = theme.colors.paperBackground
        findButton.setTitleColor(theme.colors.link, for: .normal)
        findButton.layer.borderColor = theme.colors.link.cgColor
    }
}
