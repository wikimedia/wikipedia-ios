import Foundation
import WMF

func makeEventLoggingService() -> EventLoggingService {
    let eventLoggingService = EventLoggingService(session: MWKDataStore.shared().session, permanentStorageURL: nil)
    return eventLoggingService!
    
}
