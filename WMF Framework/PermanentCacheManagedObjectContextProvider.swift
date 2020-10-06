import CoreData
import CocoaLumberjackSwift

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
    weak var delegate: ManagedObjectContextProvidingDelegate?

    private let contextCreationQueue = DispatchQueue(label: "org.wikimedia.wikipedia.cacheContextCreation")
    private lazy var managedObjectContext: NSManagedObjectContext? = {
        guard let context = CacheController.createCacheContext() else {
            DDLogError("Unable to create cache context")
            assert(false)
            return nil
        }
        return context
    }()
    
    func perform(_ block: @escaping (NSManagedObjectContext) -> Void) {
        contextCreationQueue.async { [weak self] in
            guard let context = self?.managedObjectContext else {
                return
            }
            context.perform {
                block(context)
            }
        }
    }
    
    func performAndWait(_ block: (NSManagedObjectContext) -> Void) {
        contextCreationQueue.sync {
            guard let context = managedObjectContext else {
                return
            }
            context.performAndWait {
                block(context)
            }
        }
    }
}
