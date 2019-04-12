import UIKit

class InsertMediaSearchResultsCollectionViewController: ColumnarCollectionViewController {
    var results = [MWKSearchResult]() {
        didSet {
            assert(Thread.isMainThread)
            reload()
        }
    }

    override init() {
        super.init()
        title = CommonStrings.searchTitle
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        layoutManager.register(InsertMediaSearchResultCollectionViewCell.self, forCellWithReuseIdentifier: InsertMediaSearchResultCollectionViewCell.identifier, addPlaceholder: true)
        
    }

    func reload() {
        collectionView.reloadData()
        updateEmptyState()
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return results.count
    }

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    private func configure(_ cell: InsertMediaSearchResultCollectionViewCell, at indexPath: IndexPath) {
        let result = results[indexPath.item]
        cell.imageURL = result.thumbnailURL
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
