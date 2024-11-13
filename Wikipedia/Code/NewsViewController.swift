import WMF

@objc(WMFNewsViewController)
class NewsViewController: ColumnarCollectionViewController {
    fileprivate static let cellReuseIdentifier = "NewsCollectionViewCell"
    fileprivate static let headerReuseIdentifier = "NewsCollectionViewHeader"
    
    let stories: [WMFFeedNewsStory]
    let dataStore: MWKDataStore
    let cellImageViewHeight: CGFloat = 170

    let contentGroupIDURIString: String?
    let contentGroup: WMFContentGroup?

    // For NestedCollectionViewContextMenuDelegate
    private var previewedIndex: Int?

    @objc required init(stories: [WMFFeedNewsStory], dataStore: MWKDataStore, contentGroup: WMFContentGroup?, theme: Theme) {
        self.stories = stories
        self.dataStore = dataStore
        self.contentGroup = contentGroup
        contentGroupIDURIString = contentGroup?.objectID.uriRepresentation().absoluteString
        super.init()
        self.theme = theme
        title = CommonStrings.inTheNewsTitle
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) not supported")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        layoutManager.register(NewsCollectionViewCell.self, forCellWithReuseIdentifier: NewsViewController.cellReuseIdentifier, addPlaceholder: true)
        layoutManager.register(UINib(nibName: NewsViewController.headerReuseIdentifier, bundle: nil), forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: NewsViewController.headerReuseIdentifier, addPlaceholder: false)
        collectionView.allowsSelection = false
    }
    
    override func metrics(with size: CGSize, readableWidth: CGFloat, layoutMargins: UIEdgeInsets) -> ColumnarCollectionViewLayoutMetrics {
        return ColumnarCollectionViewLayoutMetrics.tableViewMetrics(with: size, readableWidth: readableWidth, layoutMargins: layoutMargins, interSectionSpacing: 0, interItemSpacing: 22)
    }
    
    // MARK: - ColumnarCollectionViewLayoutDelegate
    override func collectionView(_ collectionView: UICollectionView, estimatedHeightForHeaderInSection section: Int, forColumnWidth columnWidth: CGFloat) -> ColumnarCollectionViewLayoutHeightEstimate {
        guard section > 0 else {
            return super.collectionView(collectionView, estimatedHeightForHeaderInSection: section, forColumnWidth: columnWidth)
        }
        return ColumnarCollectionViewLayoutHeightEstimate(precalculated: false, height: headerTitle(for: section) == nil ? 0 : 57)
    }
    
    override func collectionView(_ collectionView: UICollectionView, estimatedHeightForItemAt indexPath: IndexPath, forColumnWidth columnWidth: CGFloat) -> ColumnarCollectionViewLayoutHeightEstimate {
        var estimate = ColumnarCollectionViewLayoutHeightEstimate(precalculated: false, height: 350)
        guard let placeholderCell = layoutManager.placeholder(forCellWithReuseIdentifier: NewsViewController.cellReuseIdentifier) as? NewsCollectionViewCell else {
            return estimate
        }
        guard let story = story(for: indexPath.section) else {
            return estimate
        }
        placeholderCell.layoutMargins = layout.itemLayoutMargins
        placeholderCell.imageViewHeight = cellImageViewHeight
        placeholderCell.configure(with: story, dataStore: dataStore, theme: theme, layoutOnly: true)
        estimate.height = placeholderCell.sizeThatFits(CGSize(width: columnWidth, height: UIView.noIntrinsicMetric), apply: false).height
        estimate.precalculated = true
        return estimate
    }
    
    override func apply(theme: Theme) {
        super.apply(theme: theme)
        guard viewIfLoaded != nil else {
            return
        }
        view.backgroundColor = theme.colors.paperBackground
        collectionView.backgroundColor = theme.colors.paperBackground
    }

    override func readMoreArticlePreviewActionSelected(with articleController: ArticleViewController) {
        articleController.wmf_removePeekableChildViewControllers()
        push(articleController, animated: true)
        previewedIndex = nil
    }

    // MARK: - CollectionViewFooterDelegate

    override func collectionViewFooterButtonWasPressed(_ collectionViewFooter: CollectionViewFooter) {
        navigationController?.popViewController(animated: true)
    }
}

// MARK: - UICollectionViewDataSource
extension NewsViewController {
    
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return stories.count + 1
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return section == 0 ? 0 : 1
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: NewsViewController.cellReuseIdentifier, for: indexPath)
        guard let newsCell = cell as? NewsCollectionViewCell else {
            return cell
        }
        newsCell.layoutMargins = layout.itemLayoutMargins
        newsCell.imageViewHeight = cellImageViewHeight
        newsCell.contextMenuShowingDelegate = self
        if let story = story(for: indexPath.section) {
            newsCell.configure(with: story, dataStore: dataStore, theme: theme, layoutOnly: false)
        }
        return newsCell
    }
    
    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        guard indexPath.section > 0 else {
            return super.collectionView(collectionView, viewForSupplementaryElementOfKind: kind, at: indexPath)
        }
        switch kind {
        case UICollectionView.elementKindSectionHeader:
            let view = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: NewsViewController.headerReuseIdentifier, for: indexPath)
            guard let header = view as? NewsCollectionViewHeader else {
                return view
            }
            header.label.text = headerTitle(for: indexPath.section)
            header.apply(theme: theme)
            return header
        case UICollectionView.elementKindSectionFooter:
            return super.collectionView(collectionView, viewForSupplementaryElementOfKind: kind, at: indexPath)
        default:
            assert(false, "ensure you've registered cells and added cases to this switch statement to handle all header/footer types")
            return UICollectionReusableView()
        }
    }
    
    @objc func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        guard let cell = cell as? NewsCollectionViewCell else {
            return
        }
        cell.selectionDelegate = self
    }
    
    @objc func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        guard let cell = cell as? NewsCollectionViewCell else {
            return
        }
        cell.selectionDelegate = nil
    }
    
    static let headerDateFormatter: DateFormatter = {
        let headerDateFormatter = DateFormatter()
        headerDateFormatter.locale = Locale.autoupdatingCurrent
        headerDateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        headerDateFormatter.setLocalizedDateFormatFromTemplate("EEEEMMMMd") // Year is invalid on news content dates, we can only show month and day
        return headerDateFormatter
    }()
    
    func story(for section: Int) -> WMFFeedNewsStory? {
        guard section > 0 else {
            return nil
        }
        return stories[section - 1]
    }
    
    func headerTitle(for section: Int) -> String? {
        guard let story = story(for: section), let date = story.midnightUTCMonthAndDay else {
            return nil
        }
        return NewsViewController.headerDateFormatter.string(from: date)
    }
}

// MARK: - SideScrollingCollectionViewCellDelegate
extension NewsViewController: SideScrollingCollectionViewCellDelegate {
    func sideScrollingCollectionViewCell(_ sideScrollingCollectionViewCell: SideScrollingCollectionViewCell, didSelectArticleWithURL articleURL: URL, at indexPath: IndexPath) {
        navigate(to: articleURL)
    }
}

// MARK: - EventLoggingEventValuesProviding
extension NewsViewController: MEPEventsProviding {
    var eventLoggingCategory: EventCategoryMEP {
        return .feed
    }
    
    var eventLoggingLabel: EventLabelMEP? {
        return .news
    }
}

// MARK: - NestedCollectionViewContextMenuDelegate
extension NewsViewController: NestedCollectionViewContextMenuDelegate {
    func contextMenu(with contentGroup: WMFContentGroup? = nil, for articleURL: URL? = nil, at itemIndex: Int) -> UIContextMenuConfiguration? {
        guard let articleURL = articleURL, let vc = ArticleViewController(articleURL: articleURL, dataStore: dataStore, theme: theme) else {
            return nil
        }
        vc.articlePreviewingDelegate = self
        vc.wmf_addPeekableChildViewController(for: articleURL, dataStore: dataStore, theme: theme)
        previewedIndex = itemIndex

        let previewProvider: () -> UIViewController? = {
            return vc
        }
        return UIContextMenuConfiguration(identifier: nil, previewProvider: previewProvider) { (suggestedActions) -> UIMenu? in
            return nil

            // While we'd like to use this next line to give context menu items, the "collection view within a collection view architecture
            // results in an assertion failure in dev mode due to constraints that are automatically added by the preview's action menu, which
            // further results in the horizontally scrollable collection view being broken when coming back to it. I'm not sure that this
            // functionality was present before this re-write, and so leaving it out for now.
//              return UIMenu(title: "", image: nil, identifier: nil, options: [], children: vc.contextMenuItems)
        }
    }

    func willCommitPreview(with animator: UIContextMenuInteractionCommitAnimating) {
        guard let previewedViewController = animator.previewViewController else {
            assertionFailure("Should be able to find previewed VC")
            return
        }
        animator.addCompletion { [weak self] in
            previewedViewController.wmf_removePeekableChildViewControllers()

            guard let self = self else {
                return
            }
            self.push(previewedViewController, animated: true)
            self.previewedIndex = nil
        }
    }
}
