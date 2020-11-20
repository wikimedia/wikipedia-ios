import Foundation
import CocoaLumberjackSwift

protocol CollectionViewUpdaterDelegate: NSObjectProtocol {
    func collectionViewUpdater<T>(_ updater: CollectionViewUpdater<T>, didUpdate collectionView: UICollectionView)
    func collectionViewUpdater<T>(_ updater: CollectionViewUpdater<T>, updateItemAtIndexPath indexPath: IndexPath, in collectionView: UICollectionView)
}

class CollectionViewUpdater<T: NSFetchRequestResult>: NSObject, NSFetchedResultsControllerDelegate {
    
    let fetchedResultsController: NSFetchedResultsController<T>
    let collectionView: UICollectionView
    var isSlidingNewContentInFromTheTopEnabled: Bool = false
    var sectionChanges: [WMFSectionChange] = []
    var objectChanges: [WMFObjectChange] = []
    weak var delegate: CollectionViewUpdaterDelegate?
    
    var isGranularUpdatingEnabled: Bool = true // when set to false, individual updates won't be pushed to the collection view, only reloadData()
    
    required init(fetchedResultsController: NSFetchedResultsController<T>, collectionView: UICollectionView) {
        self.fetchedResultsController = fetchedResultsController
        self.collectionView = collectionView
        super.init()
        self.fetchedResultsController.delegate = self
    }
    
    deinit {
        self.fetchedResultsController.delegate = nil
    }
    
    public func performFetch() {
        do {
            try fetchedResultsController.performFetch()
        } catch let error {
            assert(false)
            DDLogError("Error fetching \(String(describing: fetchedResultsController.fetchRequest.predicate)) for \(String(describing: self.delegate)): \(error)")
        }
        sectionCounts = fetchSectionCounts()
        collectionView.reloadData()
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
    
    private var previousSectionCounts: [Int] = []
    private var sectionCounts: [Int] = []
    private func fetchSectionCounts() -> [Int] {
        let sections = fetchedResultsController.sections ?? []
        return sections.map { $0.numberOfObjects }
    }
    
    @objc func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        previousSectionCounts = sectionCounts
        sectionCounts = fetchSectionCounts()
        
        guard isGranularUpdatingEnabled else {
            collectionView.reloadData()
            delegate?.collectionViewUpdater(self, didUpdate: self.collectionView)
            return
        }
        
        var didInsertFirstSection = false
        var didOnlyChangeItems = true
        var sectionDelta = 0
        var objectsInSectionDelta = 0
        var forceReload = false
        
        for sectionChange in sectionChanges {
            didOnlyChangeItems = false
            switch sectionChange.type {
            case .delete:
                guard sectionChange.sectionIndex < previousSectionCounts.count else {
                    forceReload = true
                    break
                }
                sectionDelta -= 1
            case .insert:
                sectionDelta += 1
                objectsInSectionDelta += sectionCounts[sectionChange.sectionIndex]
                if sectionChange.sectionIndex == 0 {
                    didInsertFirstSection = true
                }
            default:
                break
            }
        }
        
        for objectChange in objectChanges {
            switch objectChange.type {
            case .delete:
                guard let fromIndexPath = objectChange.fromIndexPath,
                    fromIndexPath.section < previousSectionCounts.count,
                    fromIndexPath.item < previousSectionCounts[fromIndexPath.section] else {
                    forceReload = true
                    break
                }
                
                // there seems to be a very specific bug about deleting the item at index path 0,2 when there are 3 items in the section ¯\_(ツ)_/¯
                if fromIndexPath.section == 0 && fromIndexPath.item == 2 && previousSectionCounts[0] == 3 {
                    forceReload = true
                    break
                }

            default:
                break
            }
        }
        
        let sectionCountsMatch = (previousSectionCounts.count + sectionDelta) == sectionCounts.count
        guard !forceReload, sectionCountsMatch, objectChanges.count < 1000 && sectionChanges.count < 10 else { // reload data for invalid changes & larger changes
            collectionView.reloadData()
            delegate?.collectionViewUpdater(self, didUpdate: self.collectionView)
            return
        }
        
        guard isSlidingNewContentInFromTheTopEnabled else {
            performBatchUpdates()
            return
        }

        guard let columnarLayout = collectionView.collectionViewLayout as? ColumnarCollectionViewLayout else {
            performBatchUpdates()
            return
        }
        
        guard !previousSectionCounts.isEmpty && didInsertFirstSection && sectionDelta > 0 else {
            if didOnlyChangeItems {
                columnarLayout.animateItems = true
                columnarLayout.slideInNewContentFromTheTop = false
                UIView.animate(withDuration: 0.8, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: .allowUserInteraction, animations: {
                    self.performBatchUpdates()
                }, completion: nil)
            } else {
                columnarLayout.animateItems = false
                columnarLayout.slideInNewContentFromTheTop = false
                performBatchUpdates()
            }
            return
        }
        columnarLayout.animateItems = true
        columnarLayout.slideInNewContentFromTheTop = true
        UIView.animate(withDuration: 0.7 + 0.1 * TimeInterval(objectsInSectionDelta), delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: .allowUserInteraction, animations: {
            self.performBatchUpdates()
        }, completion: nil)
    }
    
    func performBatchUpdates() {
        let collectionView = self.collectionView
        collectionView.performBatchUpdates({
            DDLogDebug("=== WMFBU BATCH UPDATE START \(String(describing: self.delegate)) ===")
            for objectChange in objectChanges {
                switch objectChange.type {
                case .delete:
                    if let fromIndexPath = objectChange.fromIndexPath {
                        DDLogDebug("WMFBU object delete: \(fromIndexPath)")
                        collectionView.deleteItems(at: [fromIndexPath])
                    } else {
                        assert(false, "unhandled delete")
                        DDLogError("Unhandled delete: \(objectChange)")
                    }
                case .insert:
                    if let toIndexPath = objectChange.toIndexPath {
                        DDLogDebug("WMFBU object insert: \(toIndexPath)")
                        collectionView.insertItems(at: [toIndexPath])
                    } else {
                        assert(false, "unhandled insert")
                        DDLogError("Unhandled insert: \(objectChange)")
                    }
                case .move:
                    if let fromIndexPath = objectChange.fromIndexPath, let toIndexPath = objectChange.toIndexPath {
                        DDLogDebug("WMFBU object move delete: \(fromIndexPath)")
                        collectionView.deleteItems(at: [fromIndexPath])
                        DDLogDebug("WMFBU object move insert: \(toIndexPath)")
                        collectionView.insertItems(at: [toIndexPath])
                    } else {
                        assert(false, "unhandled move")
                        DDLogError("Unhandled move: \(objectChange)")
                    }
                    break
                case .update:
                    if let updatedIndexPath = objectChange.toIndexPath ?? objectChange.fromIndexPath {
                        delegate?.collectionViewUpdater(self, updateItemAtIndexPath: updatedIndexPath, in: collectionView)
                    } else {
                        assert(false, "unhandled update")
                        DDLogDebug("WMFBU unhandled update: \(objectChange)")
                    }
                @unknown default:
                    break
                }
            }
            
            for sectionChange in sectionChanges {
                switch sectionChange.type {
                case .delete:
                    DDLogDebug("WMFBU section delete: \(sectionChange.sectionIndex)")
                    collectionView.deleteSections(IndexSet(integer: sectionChange.sectionIndex))
                case .insert:
                    DDLogDebug("WMFBU section insert: \(sectionChange.sectionIndex)")
                    collectionView.insertSections(IndexSet(integer: sectionChange.sectionIndex))
                default:
                    DDLogDebug("WMFBU section update: \(sectionChange.sectionIndex)")
                    collectionView.reloadSections(IndexSet(integer: sectionChange.sectionIndex))
                }
            }
            DDLogDebug("=== WMFBU BATCH UPDATE END ===")
        }) { (finished) in
            self.delegate?.collectionViewUpdater(self, didUpdate: collectionView)
        }
    }
    
}
