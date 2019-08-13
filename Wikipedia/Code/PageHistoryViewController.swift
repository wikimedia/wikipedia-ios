import UIKit

fileprivate class Layout: UICollectionViewFlowLayout {
    override func invalidateLayout(with context: UICollectionViewLayoutInvalidationContext) {
        defer {
            super.invalidateLayout(with: context)
        }
        guard let collectionView = collectionView else {
            return
        }
        let countOfColumns: CGFloat = 1
        sectionInset = UIEdgeInsets(top: 15, left: minimumInteritemSpacing + collectionView.layoutMargins.left - collectionView.contentInset.left, bottom: 15, right: collectionView.layoutMargins.right - collectionView.contentInset.right + minimumInteritemSpacing)
        let availableWidth = collectionView.bounds.width - minimumInteritemSpacing * (countOfColumns - 1) - collectionView.contentInset.left - collectionView.contentInset.right - sectionInset.left - sectionInset.right
        itemSize = CGSize(width: availableWidth, height: 50)
    }
}

@objc(WMFPageHistoryViewControllerDelegate)
protocol PageHistoryViewControllerDelegate: AnyObject {
    func pageHistoryViewControllerDidDisappear(_ pageHistoryViewController: PageHistoryViewController)
}

@objc(WMFPageHistoryViewController)
class PageHistoryViewController: ViewController {
    private let pageTitle: String
    private let pageURL: URL

    private let pageHistoryFetcher = PageHistoryFetcher()
    private var pageHistoryFetcherParams: PageHistoryRequestParameters

    private var batchComplete = false
    private var isLoadingData = false

    var shouldLoadNewData: Bool {
        if batchComplete || isLoadingData {
            return false
        }
        let maxY = collectionView.contentOffset.y + collectionView.frame.size.height + 200.0;
        if (maxY >= collectionView.contentSize.height) {
            return true
        }
        return false;
    }

    private let collectionView = UICollectionView(frame: .zero, collectionViewLayout: Layout())
    private var layout: Layout {
        return collectionView.collectionViewLayout as! Layout
    }

    @objc public weak var delegate: PageHistoryViewControllerDelegate?

    private lazy var statsViewController = PageHistoryStatsViewController(pageTitle: pageTitle, locale: NSLocale.wmf_locale(for: pageURL.wmf_language))

    @objc init(pageTitle: String, pageURL: URL) {
        self.pageTitle = pageTitle
        self.pageURL = pageURL
        self.pageHistoryFetcherParams = PageHistoryRequestParameters(title: pageTitle)
        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private var pageHistorySections: [PageHistorySection] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: WMFLocalizedString("page-history-compare-title", value: "Compare", comment: "Title for action button that allows users to contrast different items"), style: .plain, target: self, action: #selector(compare(_:)))
        title = CommonStrings.historyTabTitle

        addChild(statsViewController)
        navigationBar.addUnderNavigationBarView(statsViewController.view)
        navigationBar.shadowColorKeyPath = \Theme.colors.border
        statsViewController.didMove(toParent: self)

        collectionView.register(PageHistoryCollectionViewCell.self, forCellWithReuseIdentifier: PageHistoryCollectionViewCell.identifier)
        collectionView.register(CollectionViewHeader.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: CollectionViewHeader.identifier)
        collectionView.dataSource = self
        collectionView.delegate = self
        scrollView = collectionView
        scrollView?.contentInsetAdjustmentBehavior = .never
        view.wmf_addSubviewWithConstraintsToEdges(collectionView)

        apply(theme: theme)

        // TODO: Move networking

        pageHistoryFetcher.fetchPageStats(pageTitle, pageURL: pageURL) { result in
            switch result {
            case .failure(let error):
                // TODO: Handle error
                print(error)
            case .success(let pageStats):
                DispatchQueue.main.async {
                    self.statsViewController.pageStats = pageStats
                }
            }
        }

        getPageHistory()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        delegate?.pageHistoryViewControllerDidDisappear(self)
    }

    private func getPageHistory() {
        isLoadingData = true

        pageHistoryFetcher.fetchRevisionInfo(pageURL, requestParams: pageHistoryFetcherParams, failure: { error in
            print(error)
            self.isLoadingData = false
        }) { results in
            self.pageHistorySections.append(contentsOf: results.items())
            self.pageHistoryFetcherParams = results.getPageHistoryRequestParameters(self.pageURL)
            self.batchComplete = results.batchComplete()
            self.isLoadingData = false
            DispatchQueue.main.async {
                self.collectionView.reloadData()
            }
        }
    }

    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        super.scrollViewDidScroll(scrollView)
        guard shouldLoadNewData else {
            return
        }
        getPageHistory()
    }

    @objc private func compare(_ sender: UIBarButtonItem) {

    }

    override func apply(theme: Theme) {
        super.apply(theme: theme)
        guard viewIfLoaded != nil else {
            self.theme = theme
            return
        }
        view.backgroundColor = theme.colors.paperBackground
        collectionView.backgroundColor = view.backgroundColor
        navigationItem.rightBarButtonItem?.tintColor = theme.colors.link
        navigationItem.leftBarButtonItem?.tintColor = theme.colors.primaryText
        statsViewController.apply(theme: theme)
    }
}

extension PageHistoryViewController: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return pageHistorySections.count
    }
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return pageHistorySections[section].items.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PageHistoryCollectionViewCell.identifier, for: indexPath) as? PageHistoryCollectionViewCell else {
            return UICollectionViewCell()
        }
        cell.apply(theme: theme)
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        guard
            kind == UICollectionView.elementKindSectionHeader,
            let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: CollectionViewHeader.identifier, for: indexPath) as? CollectionViewHeader
        else {
            return UICollectionReusableView()
        }
        header.style = .pageHistory
        header.title = pageHistorySections[indexPath.section].sectionTitle
        header.titleTextColorKeyPath = \Theme.colors.secondaryText
        header.apply(theme: theme)
        return header
    }
}

extension PageHistoryViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        // TODO: Make this dynamic
        // TODO: Scroll bar is below section header
        return CGSize(width: layout.itemSize.width, height: 34)
    }
}
