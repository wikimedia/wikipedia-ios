import Foundation
import WMF

func makeEventLoggingService() -> EventLoggingService {
    let eventLoggingService = EventLoggingService(session: Session.shared, permanentStorageURL: nil)
    return eventLoggingService!
    
}
