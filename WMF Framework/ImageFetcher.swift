
import Foundation

public final class ImageFetcher: Fetcher, CacheFetching {
    let permanentCacheCore: PermanentCacheCore
    
    required public init(session: Session, configuration: Configuration) {
        fatalError("ImageFetcher must be created using init(session:configuration:permanentCacheCore:)")
    }
    
    internal init(session: Session, configuration: Configuration, permanentCacheCore: PermanentCacheCore) {
        self.permanentCacheCore = permanentCacheCore
        super.init(session: session, configuration: configuration)
    }

}
