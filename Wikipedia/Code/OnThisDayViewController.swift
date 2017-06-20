@objc(WMFOnThisDayViewController)
class OnThisDayViewController: ColumnarCollectionViewController {
    fileprivate static let cellReuseIdentifier = "OnThisDayCollectionViewCell"
    fileprivate static let headerReuseIdentifier = "OnThisDayCollectionViewHeader"
    
    let events: [WMFFeedOnThisDayEvent]
    let dataStore: MWKDataStore
    
    required init(events: [WMFFeedOnThisDayEvent], dataStore: MWKDataStore) {
        self.events = events
        self.dataStore = dataStore
        super.init()
        title = WMFLocalizedString("on-this-day-title", value:"On this day", comment:"Title for the 'On this day' feed section")
        
        navigationItem.backBarButtonItem = UIBarButtonItem(title: WMFLocalizedString("back", value:"Back", comment:"Generic 'Back' title for back button\n{{Identical|Back}}"), style: .plain, target:nil, action:nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) not supported")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        register(OnThisDayCollectionViewCell.self, forCellWithReuseIdentifier: OnThisDayViewController.cellReuseIdentifier)
        register(UINib(nibName: OnThisDayViewController.headerReuseIdentifier, bundle: nil), forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: OnThisDayViewController.headerReuseIdentifier)
    }
}

// MARK: - UICollectionViewDataSource
extension OnThisDayViewController {
    
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return events.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 1
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: OnThisDayViewController.cellReuseIdentifier, for: indexPath)
        guard let onThisDayCell = cell as? OnThisDayCollectionViewCell else {
            return cell
        }
        let event = events[indexPath.section]
        onThisDayCell.configure(with: event, dataStore: dataStore, layoutOnly: false)
        return onThisDayCell
    }
    
    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        switch kind {
        case UICollectionElementKindSectionHeader:
            let view = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: OnThisDayViewController.headerReuseIdentifier, for: indexPath)
            guard let header = view as? OnThisDayCollectionViewHeader else {
                return view
            }
            header.label.text = headerTitle(for: indexPath.section)
            return header
        default:
            return UICollectionReusableView()
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        guard let cell = cell as? OnThisDayCollectionViewCell else {
            return
        }
        cell.selectionDelegate = self
    }
    
    override func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        guard let cell = cell as? OnThisDayCollectionViewCell else {
            return
        }
        cell.selectionDelegate = nil
    }
    /*
    static let headerDateFormatter: DateFormatter = {
        let headerDateFormatter = DateFormatter()
        headerDateFormatter.locale = Locale.autoupdatingCurrent
        headerDateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        headerDateFormatter.setLocalizedDateFormatFromTemplate("dMMMM") // Year is invalid on news content dates, we can only show month and day
        return headerDateFormatter
    }()
    */
    func headerTitle(for section: Int) -> String? {
        let event = events[section]
        guard let year = event.year else {
            return nil
        }
        return "\(year)"
        //return OnThisDayViewController.headerDateFormatter.string(from: date)
    }
}

// MARK: - WMFColumnarCollectionViewLayoutDelegate
extension OnThisDayViewController {
    override func collectionView(_ collectionView: UICollectionView, estimatedHeightForHeaderInSection section: Int, forColumnWidth columnWidth: CGFloat) -> CGFloat {
        return headerTitle(for: section) == nil ? 0 : 50
    }
    
    override func collectionView(_ collectionView: UICollectionView, estimatedHeightForItemAt indexPath: IndexPath, forColumnWidth columnWidth: CGFloat) -> WMFLayoutEstimate {
        return WMFLayoutEstimate(precalculated: false, height: 350)
    }
}

// MARK: - SideScrollingCollectionViewCellDelegate
extension OnThisDayViewController: SideScrollingCollectionViewCellDelegate {
    func sideScrollingCollectionViewCell(_ sideScrollingCollectionViewCell: SideScrollingCollectionViewCell, didSelectArticleWithURL articleURL: URL) {
        wmf_pushArticle(with: articleURL, dataStore: dataStore, animated: true)
    }
}

// MARK: - UIViewControllerPreviewingDelegate
extension OnThisDayViewController {
    override func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        guard let collectionView = collectionView,
            let indexPath = collectionView.indexPathForItem(at: location),
            let cell = collectionView.cellForItem(at: indexPath) as? OnThisDayCollectionViewCell else {
            return nil
        }
        
        let pointInCellCoordinates =  collectionView.convert(location, to: cell)
        let index = cell.subItemIndex(at: pointInCellCoordinates)
        guard index != NSNotFound, let view = cell.viewForSubItem(at: index) else {
            return nil
        }
        
        let event = events[indexPath.section]
        guard let previews = event.articlePreviews, index < previews.count else {
            return nil
        }
        
        previewingContext.sourceRect = view.convert(view.bounds, to: collectionView)
        let article = previews[index]
        return WMFArticleViewController(articleURL: article.articleURL, dataStore: dataStore)
    }
    
    override func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
        wmf_push(viewControllerToCommit, animated: true)
    }
}
