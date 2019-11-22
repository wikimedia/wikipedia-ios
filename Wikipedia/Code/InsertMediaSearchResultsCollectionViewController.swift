import UIKit

fileprivate class FlowLayout: UICollectionViewFlowLayout {
    override init() {
        super.init()
        minimumInteritemSpacing = 12
        minimumLineSpacing = 38
        sectionInsetReference = .fromContentInset
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func invalidationContext(forBoundsChange newBounds: CGRect) -> UICollectionViewLayoutInvalidationContext {
        let superContext = super.invalidationContext(forBoundsChange: newBounds)
        guard let context = superContext as? UICollectionViewFlowLayoutInvalidationContext else {
            return superContext
        }
        context.invalidateFlowLayoutDelegateMetrics = true
        return context
    }

    override func invalidateLayout(with context: UICollectionViewLayoutInvalidationContext) {
        defer {
            super.invalidateLayout(with: context)
        }
        guard let collectionView = collectionView else {
            return
        }
        let countOfColumns: CGFloat = 3
        sectionInset = UIEdgeInsets(top: 12, left: minimumInteritemSpacing + collectionView.layoutMargins.left - collectionView.contentInset.left, bottom: 0, right: collectionView.layoutMargins.right  - collectionView.contentInset.right + minimumInteritemSpacing)
        let availableWidth = collectionView.bounds.width - minimumInteritemSpacing * (countOfColumns - 1) - collectionView.contentInset.left - collectionView.contentInset.right - sectionInset.left - sectionInset.right
        let dimension = floor(availableWidth / countOfColumns)
        itemSize = CGSize(width: dimension, height: dimension)
    }
}

protocol InsertMediaSearchResultsCollectionViewControllerDelegate: AnyObject {
    func insertMediaSearchResultsCollectionViewControllerDidSelect(_ insertMediaSearchResultsCollectionViewController: InsertMediaSearchResultsCollectionViewController, searchResult: InsertMediaSearchResult)
}

protocol InsertMediaSearchResultsCollectionViewControllerScrollDelegate: AnyObject {
    func insertMediaSearchResultsCollectionViewController(_ insertMediaSearchResultsCollectionViewController: InsertMediaSearchResultsCollectionViewController, scrollViewDidScroll scrollView: UIScrollView)
    func insertMediaSearchResultsCollectionViewController(_ insertMediaSearchResultsCollectionViewController: InsertMediaSearchResultsCollectionViewController, scrollViewWillBeginDragging scrollView: UIScrollView)
    func insertMediaSearchResultsCollectionViewController(_ insertMediaSearchResultsCollectionViewController: InsertMediaSearchResultsCollectionViewController, scrollViewWillEndDragging scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>)
    func insertMediaSearchResultsCollectionViewController(_ insertMediaSearchResultsCollectionViewController: InsertMediaSearchResultsCollectionViewController, scrollViewDidEndDecelerating scrollView: UIScrollView)
    func insertMediaSearchResultsCollectionViewController(_ insertMediaSearchResultsCollectionViewController: InsertMediaSearchResultsCollectionViewController, scrollViewDidEndScrollingAnimation scrollView: UIScrollView)
    func insertMediaSearchResultsCollectionViewController(_ insertMediaSearchResultsCollectionViewController: InsertMediaSearchResultsCollectionViewController, scrollViewShouldScrollToTop scrollView: UIScrollView) -> Bool
    func insertMediaSearchResultsCollectionViewController(_ insertMediaSearchResultsCollectionViewController: InsertMediaSearchResultsCollectionViewController, scrollViewDidScrollToTop scrollView: UIScrollView)
}

final class InsertMediaSearchResult {
    let fileTitle: String
    let displayTitle: String
    let thumbnailURL: URL
    var imageInfo: MWKImageInfo?

    init(fileTitle: String, displayTitle: String, thumbnailURL: URL) {
        self.fileTitle = fileTitle
        self.displayTitle = displayTitle
        self.thumbnailURL = thumbnailURL
    }

    func imageURL(for width: CGFloat) -> URL? {
        guard width > 0 else {
            assertionFailure("width must be greater than 0")
            return nil
        }
        return URL(string: WMFChangeImageSourceURLSizePrefix(thumbnailURL.absoluteString, Int(width))) ?? imageInfo?.canonicalFileURL
    }
}

class InsertMediaSearchResultsCollectionViewController: UICollectionViewController {
    private var theme = Theme.standard
    private var flowLayout: FlowLayout {
        return collectionView.collectionViewLayout as! FlowLayout
    }

    weak var delegate: InsertMediaSearchResultsCollectionViewControllerDelegate?
    weak var scrollDelegate: InsertMediaSearchResultsCollectionViewControllerScrollDelegate?

    var searchResults = [InsertMediaSearchResult]() {
        didSet {
            assert(Thread.isMainThread)
            reload()
        }
    }

    var selectedImage: UIImage? {
        guard
            let selectedIndexPath = collectionView.indexPathsForSelectedItems?.first,
            let cell = collectionView.cellForItem(at: selectedIndexPath) as? InsertMediaSearchResultCollectionViewCell
        else {
            return nil
        }
        return cell.imageView.image
    }

    init() {
        super.init(collectionViewLayout: FlowLayout())
        collectionView.contentInsetAdjustmentBehavior = .never
        title = CommonStrings.searchTitle
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.register(InsertMediaSearchResultCollectionViewCell.self, forCellWithReuseIdentifier: InsertMediaSearchResultCollectionViewCell.identifier)
        additionalSafeAreaInsets = UIEdgeInsets(top: 0, left: 0, bottom: flowLayout.minimumLineSpacing, right: 0)
        registerForPreviewing(with: self, sourceView: collectionView)
        apply(theme: theme)
    }

    func reload() {
        collectionView.reloadData()
        updateEmptyState()
    }

    private func configure(_ cell: InsertMediaSearchResultCollectionViewCell, at indexPath: IndexPath) {
        let result = searchResults[indexPath.item]
        cell.configure(imageURL: result.thumbnailURL, caption: result.displayTitle)
        cell.apply(theme: theme)
    }

    func setImageInfo(_ imageInfo: MWKImageInfo?, for searchResult: InsertMediaSearchResult, at index: Int) {
        assert(Thread.isMainThread)
        searchResult.imageInfo = imageInfo
    }

    // MARK: Themeable

    func apply(theme: Theme) {
        self.theme = theme
        guard viewIfLoaded != nil else {
            return
        }
        view.backgroundColor = theme.colors.paperBackground
        collectionView.backgroundColor = theme.colors.paperBackground
        collectionView.reloadData()
    }

    // MARK: - Empty State

    var emptyViewType: WMFEmptyViewType = .noSearchResults

    final var isEmpty = true
    final var showingEmptyViewType: WMFEmptyViewType?
    final func updateEmptyState() {
        let sectionCount = numberOfSections(in: collectionView)

        var isCurrentlyEmpty = true
        for sectionIndex in 0..<sectionCount {
            if self.collectionView(collectionView, numberOfItemsInSection: sectionIndex) > 0 {
                isCurrentlyEmpty = false
                break
            }
        }

        guard isCurrentlyEmpty != isEmpty || showingEmptyViewType != emptyViewType else {
            return
        }

        isEmpty = isCurrentlyEmpty

        isEmptyDidChange()
    }

    private var emptyViewFrame: CGRect {
        let insets = collectionView?.contentInset ?? UIEdgeInsets.zero
        let frame = view.bounds.inset(by: insets)
        return frame
    }

    open func isEmptyDidChange() {
        if isEmpty {
            wmf_showEmptyView(of: emptyViewType, theme: theme, frame: emptyViewFrame)
            showingEmptyViewType = emptyViewType
        } else {
            wmf_hideEmptyView()
            showingEmptyViewType = nil
        }
    }

    func scrollViewInsetsDidChange() {
        wmf_setEmptyViewFrame(emptyViewFrame)
    }

    // MARK: Scroll view delegate

    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        scrollDelegate?.insertMediaSearchResultsCollectionViewController(self, scrollViewDidScroll: scrollView)
    }

    override func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        scrollDelegate?.insertMediaSearchResultsCollectionViewController(self, scrollViewWillBeginDragging: scrollView)
    }

    override func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        scrollDelegate?.insertMediaSearchResultsCollectionViewController(self, scrollViewWillEndDragging: scrollView, withVelocity: velocity, targetContentOffset: targetContentOffset)
    }

    override func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        scrollDelegate?.insertMediaSearchResultsCollectionViewController(self, scrollViewDidEndDecelerating: scrollView)
    }

    override func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        scrollDelegate?.insertMediaSearchResultsCollectionViewController(self, scrollViewDidEndScrollingAnimation: scrollView)
    }

    override func scrollViewShouldScrollToTop(_ scrollView: UIScrollView) -> Bool {
        return scrollDelegate?.insertMediaSearchResultsCollectionViewController(self, scrollViewShouldScrollToTop: scrollView) ?? true
    }

    override func scrollViewDidScrollToTop(_ scrollView: UIScrollView) {
        scrollDelegate?.insertMediaSearchResultsCollectionViewController(self, scrollViewDidScrollToTop: scrollView)
    }
}

extension InsertMediaSearchResultsCollectionViewController {
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return searchResults.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: InsertMediaSearchResultCollectionViewCell.identifier, for: indexPath)
        guard let searchResultCell = cell as? InsertMediaSearchResultCollectionViewCell else {
            return cell
        }
        configure(searchResultCell, at: indexPath)
        return searchResultCell
    }
}

extension InsertMediaSearchResultsCollectionViewController {
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let searchResult = searchResults[indexPath.item]
        delegate?.insertMediaSearchResultsCollectionViewControllerDidSelect(self, searchResult: searchResult)
    }
}

extension InsertMediaSearchResultsCollectionViewController: UIViewControllerPreviewingDelegate {
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
        //
    }

    final func collectionViewIndexPathForPreviewingContext(_ previewingContext: UIViewControllerPreviewing, location: CGPoint) -> IndexPath? {
        guard
            let indexPath = collectionView.indexPathForItem(at: location),
            let cell = collectionView.cellForItem(at: indexPath)
        else {
            return nil
        }
        previewingContext.sourceRect = view.convert(cell.bounds, from: cell)
        return indexPath
    }

    func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        guard
            let indexPath = collectionViewIndexPathForPreviewingContext(previewingContext, location: location),
            let searchResult = searchResults[safeIndex: indexPath.item],
            let imageURL = searchResult.imageURL(for: view.bounds.width)
        else {
            return nil
        }
        let previewingViewController = InsertMediaSearchResultPreviewingViewController(imageURL: imageURL, searchResult: searchResult)
        previewingViewController.selectImageAction = {
            self.collectionView.selectItem(at: indexPath, animated: true, scrollPosition: .centeredVertically)
            self.delegate?.insertMediaSearchResultsCollectionViewControllerDidSelect(self, searchResult: searchResult)
        }
        previewingViewController.moreInformationAction = { url in
            self.navigate(to: url, useSafari: true)
        }
        previewingViewController.apply(theme: theme)
        return previewingViewController
    }
}
