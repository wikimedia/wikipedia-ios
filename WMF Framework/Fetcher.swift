import UIKit

@objc(WMFFetcher)
open class Fetcher: NSObject {
    @objc public let configuration: Configuration
    @objc public let session: Session
    
    @objc required public init(session: Session, configuration: Configuration) {
        self.session = session
        self.configuration = configuration
    }
}
