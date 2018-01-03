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
                    DDLogDebug("section delete: \(sectionChange.sectionIndex)")
                    collectionView.deleteSections(IndexSet(integer: sectionChange.sectionIndex))
                    deletedSections.add(sectionChange.sectionIndex)
                case .insert:
                    DDLogDebug("section insert: \(sectionChange.sectionIndex)")
                    collectionView.insertSections(IndexSet(integer: sectionChange.sectionIndex))
                    insertedSections.add(sectionChange.sectionIndex)
                default:
                    DDLogDebug("section update: \(sectionChange.sectionIndex)")
                    collectionView.reloadSections(IndexSet(integer: sectionChange.sectionIndex))
                    updatedSections.add(sectionChange.sectionIndex)
                }
            }
            for objectChange in objectChanges {
                switch objectChange.type {
                case .delete:
                    if let fromIndexPath = objectChange.fromIndexPath {
                        if !deletedSections.contains(fromIndexPath.section) {
                            DDLogDebug("object delete: \(fromIndexPath)")
                            collectionView.deleteItems(at: [fromIndexPath])
                        }
                    }
                case .insert:
                    if let toIndexPath = objectChange.toIndexPath {
                        DDLogDebug("object insert: \(toIndexPath)")
                        collectionView.insertItems(at: [toIndexPath])
                    }
                case .move:
                    DDLogDebug("object move (fallthrough)")
                    fallthrough
                default:
                    if let fromIndexPath = objectChange.fromIndexPath, let toIndexPath = objectChange.toIndexPath, toIndexPath != fromIndexPath {
                        DDLogDebug("object move: \(fromIndexPath) \(toIndexPath)")
                        if deletedSections.contains(fromIndexPath.section) {
                            DDLogDebug("inserting: \(toIndexPath)")
                            collectionView.insertItems(at: [toIndexPath])
                        } else {
                            DDLogDebug("moving: \(fromIndexPath) \(toIndexPath)")
                            collectionView.moveItem(at: fromIndexPath, to: toIndexPath)
                        }
                    } else if let updatedIndexPath = objectChange.toIndexPath ?? objectChange.fromIndexPath {
                        DDLogDebug("object update: \(updatedIndexPath)")
                        if insertedSections.contains(updatedIndexPath.section) {
                            DDLogDebug("inserting: \(updatedIndexPath)")
                            collectionView.insertItems(at: [updatedIndexPath])
                        } else {
                            DDLogDebug("reloading: \(updatedIndexPath)")
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
