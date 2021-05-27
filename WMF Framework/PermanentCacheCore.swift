import Foundation

/** The PermanentCacheCore is the lowest layer of the permanent cache.
 *  It serves as a fallback for standard URLCache behavior for PermanentlyPersistableURLCache.
 *  The article and image cache controller subsystems both sit on top of PermanentCacheCore.
 */
class PermanentCacheCore {
    let cacheManagedObjectContext: NSManagedObjectContext

    init(moc: NSManagedObjectContext) {
        cacheManagedObjectContext = moc
    }
    
}
