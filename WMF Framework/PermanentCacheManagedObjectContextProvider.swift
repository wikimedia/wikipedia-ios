import CoreData
import WMF.WMFCrossProcessCoreDataSynchronizer

@objc(WMFManagedObjectContextProvidingDelegate)
public protocol ManagedObjectContextProvidingDelegate: NSObjectProtocol {
    func managedObjectContextProvider(_ provider: ManagedObjectContextProviding, didCreate managedObjectContext: NSManagedObjectContext)
}

@objc(WMFManagedObjectContextProviding)
public protocol ManagedObjectContextProviding: NSObjectProtocol {
    func perform(_ block: @escaping (NSManagedObjectContext) -> Void)
    func performAndWait(_ block: (NSManagedObjectContext) -> Void)
    weak var delegate: ManagedObjectContextProvidingDelegate? { get set }
}

class PermanentCacheManagedObjectContextProvider: NSObject, ManagedObjectContextProviding {
    var cacheURL: URL?
    var managedObjectContext: NSManagedObjectContext?
    weak var delegate: ManagedObjectContextProvidingDelegate?
    let contextCreationQueue = DispatchQueue(label: "org.wikimedia.wikipedia.cacheContextCreation")
    func perform(_ block: @escaping (NSManagedObjectContext) -> Void) {
        contextCreationQueue.async { [weak self] in
            guard let self = self else {
                return
            }
            if let context = self.managedObjectContext {
                context.perform {
                    block(context)
                }
                return
            }
            guard let context = CacheController.createCacheContext() else {
                DDLogError("Unable to create cache context")
                assert(false)
                return
            }
            self.delegate?.managedObjectContextProvider(self, didCreate: context)
            self.managedObjectContext = context
            context.perform {
                block(context)
            }
        }
    }
    
    func performAndWait(_ block: (NSManagedObjectContext) -> Void) {
        contextCreationQueue.sync {
            if let context = managedObjectContext {
                context.performAndWait {
                    block(context)
                }
                return
            }
            guard let context = CacheController.createCacheContext() else {
                DDLogError("Unable to create cache context")
                assert(false)
                return
            }
            managedObjectContext = context
            context.performAndWait {
                block(context)
            }
        }
    }
}
