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
            let insertedSections = NSMutableIndexSet()
            let deletedSections = NSMutableIndexSet()
            let updatedSections = NSMutableIndexSet()
            for sectionChange in sectionChanges {
                switch sectionChange.type {
                case .delete:
                    collectionView.deleteSections(IndexSet(integer: sectionChange.sectionIndex))
                    deletedSections.add(sectionChange.sectionIndex)
                case .insert:
                    collectionView.insertSections(IndexSet(integer: sectionChange.sectionIndex))
                    insertedSections.add(sectionChange.sectionIndex)
                default:
                    collectionView.reloadSections(IndexSet(integer: sectionChange.sectionIndex))
                    updatedSections.add(sectionChange.sectionIndex)
                }
            }
            for objectChange in objectChanges {
                switch objectChange.type {
                case .delete:
                    if let fromIndexPath = objectChange.fromIndexPath {
                        collectionView.deleteItems(at: [fromIndexPath])
                    }
                case .insert:
                    if let toIndexPath = objectChange.toIndexPath {
                        collectionView.insertItems(at: [toIndexPath])
                    }
                case .move:
                    fallthrough
                default:
                    if let fromIndexPath = objectChange.fromIndexPath, let toIndexPath = objectChange.toIndexPath, toIndexPath != fromIndexPath {
                        if deletedSections.contains(fromIndexPath.section) {
                            collectionView.insertItems(at: [toIndexPath])
                        } else {
                            collectionView.moveItem(at: fromIndexPath, to: toIndexPath)
                        }
                    } else if let updatedIndexPath = objectChange.toIndexPath ?? objectChange.fromIndexPath {
                        if insertedSections.contains(updatedIndexPath.section) {
                            collectionView.insertItems(at: [updatedIndexPath])
                        } else {
                            collectionView.reloadItems(at: [updatedIndexPath])
                        }
                    }
                }
            }
        }) { (done) in
            self.delegate?.collectionViewUpdater(self, didUpdate: collectionView)
        }
    }
    
}
