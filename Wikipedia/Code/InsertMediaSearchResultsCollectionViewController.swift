import UIKit
import SafariServices

fileprivate class FlowLayout: UICollectionViewFlowLayout {
    private var oldBoundsWidth: CGFloat = 0

    override init() {
        super.init()
        minimumInteritemSpacing = 8
        minimumLineSpacing = 32
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        defer {
            oldBoundsWidth = newBounds.width
        }
        return super.shouldInvalidateLayout(forBoundsChange: newBounds) || newBounds.width != oldBoundsWidth
    }

    override func invalidateLayout(with context: UICollectionViewLayoutInvalidationContext) {
        defer {
            super.invalidateLayout(with: context)
        }

        guard let collectionView = collectionView else {
            return
        }
        sectionInset.left = collectionView.scrollIndicatorInsets.left
        sectionInset.right = collectionView.scrollIndicatorInsets.right
        let dimension = (collectionView.bounds.width / 3) - minimumInteritemSpacing * 2 - sectionInset.left - sectionInset.right
        itemSize = CGSize(width: dimension, height: dimension)
    }
}

protocol InsertMediaSearchResultsCollectionViewControllerDelegate: AnyObject {
    func insertMediaSearchResultsCollectionViewControllerDidSelect(_ insertMediaSearchResultsCollectionViewController: InsertMediaSearchResultsCollectionViewController, searchResult: InsertMediaSearchResult)
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

class InsertMediaSearchResultsCollectionViewController: ViewController {
    private let collectionView: UICollectionView
    private var flowLayout: FlowLayout {
        return collectionView.collectionViewLayout as! FlowLayout
    }

    weak var delegate: InsertMediaSearchResultsCollectionViewControllerDelegate?

    var searchResults = [InsertMediaSearchResult]() {
        didSet {
            assert(Thread.isMainThread)
            reload()
        }
    }

    override init() {
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: FlowLayout())
        super.init()
        collectionView.dataSource = self
        collectionView.delegate = self
        scrollView = collectionView
        title = CommonStrings.searchTitle
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.register(InsertMediaSearchResultCollectionViewCell.self, forCellWithReuseIdentifier: InsertMediaSearchResultCollectionViewCell.identifier)
        view.wmf_addSubviewWithConstraintsToEdges(collectionView)
        additionalSafeAreaInsets = UIEdgeInsets(top: 0, left: 0, bottom: flowLayout.minimumLineSpacing, right: 0)
        collectionView.contentInset = UIEdgeInsets(top: 0, left: 12, bottom: 0, right: 12)
        apply(theme: theme)
    }

    func reload() {
        collectionView.reloadData()
        updateEmptyState()
    }

    private func configure(_ cell: InsertMediaSearchResultCollectionViewCell, at indexPath: IndexPath) {
        let result = searchResults[indexPath.item]
        cell.configure(imageURL: result.thumbnailURL, imageViewDimension: flowLayout.itemSize.width, caption: result.displayTitle)
        cell.apply(theme: theme)
    }

    func setImageInfo(_ imageInfo: MWKImageInfo?, for searchResult: InsertMediaSearchResult, at index: Int) {
        assert(Thread.isMainThread)
        searchResult.imageInfo = imageInfo
    }

    // MARK: Themeable

    override func apply(theme: Theme) {
        super.apply(theme: theme)
        view.backgroundColor = theme.colors.paperBackground
        collectionView.backgroundColor = theme.colors.paperBackground
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
        let insets = scrollView?.contentInset ?? UIEdgeInsets.zero
        let frame = view.bounds.inset(by: insets)
        return frame
    }

    open func isEmptyDidChange() {
        if isEmpty {
            wmf_showEmptyView(of: emptyViewType, action: nil, theme: theme, frame: emptyViewFrame)
            showingEmptyViewType = emptyViewType
        } else {
            wmf_hideEmptyView()
            showingEmptyViewType = nil
        }
    }

    override func scrollViewInsetsDidChange() {
        super.scrollViewInsetsDidChange()
        wmf_setEmptyViewFrame(emptyViewFrame)
        let context = UICollectionViewFlowLayoutInvalidationContext()
        context.invalidateFlowLayoutAttributes = true
        flowLayout.invalidateLayout(with: context)
    }
}

extension InsertMediaSearchResultsCollectionViewController: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return searchResults.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: InsertMediaSearchResultCollectionViewCell.identifier, for: indexPath)
        guard let searchResultCell = cell as? InsertMediaSearchResultCollectionViewCell else {
            return cell
        }
        configure(searchResultCell, at: indexPath)
        return searchResultCell
    }
}

extension InsertMediaSearchResultsCollectionViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let searchResult = searchResults[indexPath.item]
        delegate?.insertMediaSearchResultsCollectionViewControllerDidSelect(self, searchResult: searchResult)
    }
}

extension InsertMediaSearchResultsCollectionViewController {
    final func collectionViewIndexPathForPreviewingContext(_ previewingContext: UIViewControllerPreviewing, location: CGPoint) -> IndexPath? {
        let translatedLocation = view.convert(location, to: collectionView)
        guard
            let indexPath = collectionView.indexPathForItem(at: translatedLocation),
            let cell = collectionView.cellForItem(at: indexPath)
        else {
            return nil
        }
        previewingContext.sourceRect = view.convert(cell.bounds, from: cell)
        return indexPath
    }

    override func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
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
            self.present(SFSafariViewController(url: url), animated: true)
        }
        previewingViewController.apply(theme: theme)
        return previewingViewController
    }
}
