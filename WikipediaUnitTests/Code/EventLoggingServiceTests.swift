import Foundation
import WMF

func makeEventLoggingService() -> EventLoggingService {
    let eventLoggingService = EventLoggingService(session: MWKDataStore.temporary().session, permanentStorageURL: nil)
    return eventLoggingService!
    
}
