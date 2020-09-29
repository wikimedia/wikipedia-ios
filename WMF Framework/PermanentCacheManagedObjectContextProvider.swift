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
    var cacheURL: URL?
    var managedObjectContext: NSManagedObjectContext?
    weak var delegate: ManagedObjectContextProvidingDelegate?
    let contextCreationQueue = DispatchQueue(label: "org.wikimedia.wikipedia.cacheContextCreation")
    func perform(_ block: @escaping (NSManagedObjectContext) -> Void) {
        createContext { (context) in
            context.perform {
                block(context)
            }
        }
    }
    
    func performAndWait(_ block: (NSManagedObjectContext) -> Void) {
        createContext { (context) in
            context.performAndWait {
                block(context)
            }
        }
    }
    
    private func createContext(_ block: (NSManagedObjectContext) -> Void) {
        // Expensive file & db operations happen as a part of this migration, so async it to a non-main queue
        contextCreationQueue.sync {
            if let context = managedObjectContext {
                block(context)
                return
            }
            guard let context = CacheController.createCacheContext() else {
                DDLogError("Unable to create cache context")
                assert(false)
                return
            }
            managedObjectContext = context
            block(context)
        }
    }
}
