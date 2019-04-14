import UIKit

fileprivate class FlowLayout: UICollectionViewFlowLayout {
    private var oldBoundsWidth: CGFloat = 0

    override init() {
        super.init()
        minimumInteritemSpacing = 8
        minimumLineSpacing = 8
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

        let dimension = (collectionView.bounds.width / 3) - minimumInteritemSpacing * 2
        itemSize = CGSize(width: dimension, height: dimension)
    }
}

class InsertMediaSearchResultsCollectionViewController: ViewController {
    private let flowLayout: FlowLayout
    private let collectionView: UICollectionView
    private let itemDimension: CGFloat = 100

    var results = [MWKSearchResult]() {
        didSet {
            assert(Thread.isMainThread)
            reload()
        }
    }

    override init() {
        flowLayout = FlowLayout()
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: flowLayout)
        super.init()
        collectionView.dataSource = self
        collectionView.delegate = self
        title = CommonStrings.searchTitle
    }


    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.register(InsertMediaSearchResultCollectionViewCell.self, forCellWithReuseIdentifier: InsertMediaSearchResultCollectionViewCell.identifier)
        // TODO: Fix insets
        view.wmf_addSubviewWithConstraintsToEdges(collectionView)
        collectionView.contentInset = UIEdgeInsets(top: 0, left: 12, bottom: 12, right: 12)
        collectionView.contentInsetAdjustmentBehavior = .never
        scrollView = collectionView
        apply(theme: theme)
    }

    func reload() {
        collectionView.reloadData()
        // TODO: updateEmptyState()
    }

    private func configure(_ cell: InsertMediaSearchResultCollectionViewCell, at indexPath: IndexPath) {
        let result = results[indexPath.item]
        cell.configure(imageURL: result.thumbnailURL, imageViewDimension: itemDimension, title: result.displayTitle)
    }

    // MARK: Themeable

    override func apply(theme: Theme) {
        super.apply(theme: theme)
        view.backgroundColor = theme.colors.paperBackground
        collectionView.backgroundColor = theme.colors.paperBackground
    }
}

extension InsertMediaSearchResultsCollectionViewController: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return results.count
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

}

extension InsertMediaSearchResultsCollectionViewController: UISearchBarDelegate {
    
}
