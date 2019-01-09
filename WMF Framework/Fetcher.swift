import UIKit

open class Fetcher: NSObject {
    public let configuration: Configuration
    public let session: Session
    
    @objc required public init(session: Session, configuration: Configuration) {
        self.session = session
        self.configuration = configuration
    }
}
