import UIKit

class InsertMediaSearchCollectionViewController: ColumnarCollectionViewController {
    override init() {
        super.init()
        title = CommonStrings.searchTitle
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func apply(theme: Theme) {
        super.apply(theme: theme)
        collectionView.backgroundColor = UIColor.orange
    }
}

extension InsertMediaSearchCollectionViewController: UISearchBarDelegate {
    
}
