@objc(WMFNewsViewController)
class NewsViewController: UICollectionViewController {
    static let cellReuseIdentifier = "NewsCollectionViewCell"
    static let headerReuseIdentifier = "NewsCollectionViewHeader"
    
    let stories: [WMFFeedNewsStory]
    let dataStore: MWKDataStore
    let layout: WMFColumnarCollectionViewLayout = WMFColumnarCollectionViewLayout()
    
    required init(stories: [WMFFeedNewsStory], dataStore: MWKDataStore) {
        self.stories = stories
        self.dataStore = dataStore
        super.init(collectionViewLayout: layout)
        title = WMFLocalizedString("in-the-news-title", value:"In the news", comment:"Title for the 'In the news' notification & feed section")
        navigationItem.backBarButtonItem = UIBarButtonItem(title: WMFLocalizedString("back", value:"Back", comment:"Generic 'Back' title for back button\n{{Identical|Back}}"), style: .plain, target:nil, action:nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        return nil
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView?.backgroundColor = .wmf_settingsBackground
        collectionView?.register(NewsCollectionViewCell.self, forCellWithReuseIdentifier: NewsViewController.cellReuseIdentifier)
        collectionView?.register(UINib(nibName: NewsViewController.headerReuseIdentifier, bundle: nil), forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: NewsViewController.headerReuseIdentifier)
    }
    
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return stories.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 1
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: NewsViewController.cellReuseIdentifier, for: indexPath)
        guard let newsCell = cell as? NewsCollectionViewCell else {
            return cell
        }
        let story = stories[indexPath.section]
        newsCell.configure(with: story, dataStore: dataStore, layoutOnly: false)
        return newsCell
    }
    
    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        switch kind {
        case UICollectionElementKindSectionHeader:
            let view = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: NewsViewController.headerReuseIdentifier, for: indexPath)
            guard let header = view as? NewsCollectionViewHeader else {
                return view
            }
            header.label.text = headerTitle(for: indexPath.section)
            return header
        default:
            return UICollectionReusableView()
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        guard let cell = cell as? NewsCollectionViewCell else {
            return
        }
        cell.newsDelegate = self
    }
    
    override func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        guard let cell = cell as? NewsCollectionViewCell else {
            return
        }
        cell.newsDelegate = nil
    }
    
    static var headerDateFormatter: DateFormatter = {
        let dateTemplate = "dMMMM"
        let dateFormat = DateFormatter.dateFormat(fromTemplate: dateTemplate, options: 0, locale: Locale.autoupdatingCurrent)
        let headerDateFormatter = DateFormatter()
        headerDateFormatter.dateFormat = dateFormat
        return headerDateFormatter
    }()
    
    func headerTitle(for section: Int) -> String? {
        let story = stories[section]
        guard let date = story.midnightUTCMonthAndDay else {
            return nil
        }
        return NewsViewController.headerDateFormatter.string(from: date)
    }
}

extension NewsViewController: WMFColumnarCollectionViewLayoutDelegate {
    func collectionView(_ collectionView: UICollectionView, prefersWiderColumnForSectionAt index: UInt) -> Bool {
        return index % 2 == 0
    }

    func collectionView(_ collectionView: UICollectionView, estimatedHeightForHeaderInSection section: Int, forColumnWidth columnWidth: CGFloat) -> CGFloat {
        return headerTitle(for: section) == nil ? 0 : 50
    }
    
    func collectionView(_ collectionView: UICollectionView, estimatedHeightForFooterInSection section: Int, forColumnWidth columnWidth: CGFloat) -> CGFloat {
        return 0
    }

    func collectionView(_ collectionView: UICollectionView, estimatedHeightForItemAt indexPath: IndexPath, forColumnWidth columnWidth: CGFloat) -> WMFLayoutEstimate {
        return WMFLayoutEstimate(precalculated: false, height: 350)
    }
}

extension NewsViewController: NewsCollectionViewCellDelegate {
    func newsCollectionViewCell(_ newsCollectionViewCell: NewsCollectionViewCell, didSelectNewsArticleWithURL articleURL: URL) {
        wmf_pushArticle(with: articleURL, dataStore: dataStore, animated: true)
    }
}
