import UIKit

class InsertMediaSearchCollectionViewController: ColumnarCollectionViewController {
    override init() {
        super.init()
        title = CommonStrings.searchTitle
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
