import Foundation

protocol CollectionViewUpdaterDelegate: NSObjectProtocol {
    func collectionViewUpdater<T>(_ updater: CollectionViewUpdater<T>, didUpdate collectionView: UICollectionView)
}

class CollectionViewUpdater<T: NSFetchRequestResult>: NSObject, NSFetchedResultsControllerDelegate {
    
    let fetchedResultsController: NSFetchedResultsController<T>
    let collectionView: UICollectionView
    var sectionChanges: [WMFSectionChange] = []
    var objectChanges: [WMFObjectChange] = []
    weak var delegate: CollectionViewUpdaterDelegate?
    
    required init(fetchedResultsController: NSFetchedResultsController<T>, collectionView: UICollectionView) {
        self.fetchedResultsController = fetchedResultsController
        self.collectionView = collectionView
        super.init()
        self.fetchedResultsController.delegate = self;
    }
    
    @objc func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        sectionChanges = []
        objectChanges = []
    }
    
    @objc func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        let objectChange = WMFObjectChange()
        objectChange.fromIndexPath = indexPath
        objectChange.toIndexPath = newIndexPath
        objectChange.type = type
        objectChanges.append(objectChange)
    }
    
    @objc func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
        let sectionChange = WMFSectionChange()
        sectionChange.sectionIndex = sectionIndex
        sectionChange.type = type
        sectionChanges.append(sectionChange)
    }
    
    @objc func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        let collectionView = self.collectionView
        collectionView.performBatchUpdates({
            for sectionChange in sectionChanges {
                switch sectionChange.type {
                case .delete:
                    collectionView.deleteSections(IndexSet(integer: sectionChange.sectionIndex))
                case .insert:
                    collectionView.insertSections(IndexSet(integer: sectionChange.sectionIndex))
                default:
                    collectionView.reloadSections(IndexSet(integer: sectionChange.sectionIndex))
                }
            }
            for objectChange in objectChanges {
                switch objectChange.type {
                case .delete:
                    collectionView.deleteItems(at: [objectChange.fromIndexPath!])
                case .insert:
                    collectionView.insertItems(at: [objectChange.toIndexPath!])
                case .move:
                    collectionView.moveItem(at: objectChange.fromIndexPath!, to: objectChange.toIndexPath!)
                default:
                    collectionView.reloadItems(at: [objectChange.fromIndexPath!])
                }
            }
        }) { (done) in
            collectionView.reloadItems(at: collectionView.indexPathsForVisibleItems)
            self.delegate?.collectionViewUpdater(self, didUpdate: collectionView)
        }
    }
    
}
