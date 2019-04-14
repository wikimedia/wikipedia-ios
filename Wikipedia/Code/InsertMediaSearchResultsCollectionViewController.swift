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

class InsertMediaSearchResultsCollectionViewController: UICollectionViewController {
    private let flowLayout: FlowLayout
    private var theme = Theme.standard
    private let itemDimension: CGFloat = 100

    var results = [MWKSearchResult]() {
        didSet {
            assert(Thread.isMainThread)
            reload()
        }
    }

    init() {
        flowLayout = FlowLayout()
        super.init(collectionViewLayout: flowLayout)
        title = CommonStrings.searchTitle
    }


    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.register(InsertMediaSearchResultCollectionViewCell.self, forCellWithReuseIdentifier: InsertMediaSearchResultCollectionViewCell.identifier)
        // TODO: Make this VC a ViewController so that it can work with the nav bar
        collectionView.contentInset = UIEdgeInsets(top: 120, left: 12, bottom: 0, right: 12)
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
}

extension InsertMediaSearchResultsCollectionViewController {
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return results.count
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

extension InsertMediaSearchResultsCollectionViewController: UISearchBarDelegate {
    
}

extension InsertMediaSearchResultsCollectionViewController: Themeable {
    func apply(theme: Theme) {
        self.theme = theme
        guard viewIfLoaded != nil else {
            return
        }
        view.backgroundColor = theme.colors.paperBackground
        collectionView.backgroundColor = theme.colors.paperBackground
    }
}
