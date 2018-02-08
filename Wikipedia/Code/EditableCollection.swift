public protocol EditableCollection: NSObjectProtocol {
    var editController: CollectionViewEditController! { get set }
    func setupEditController(with collectionView: UICollectionView)
}

extension EditableCollection where Self: ActionDelegate {
    func setupEditController(with collectionView: UICollectionView) {
        editController = CollectionViewEditController(collectionView: collectionView)
        editController.delegate = self
    }
}

extension EditableCollection where Self: ActionDelegate & BatchEditNavigationDelegate {
    func setupEditController(with collectionView: UICollectionView) {
        editController = CollectionViewEditController(collectionView: collectionView)
        editController.delegate = self
        editController.navigationDelegate = self
    }
}
