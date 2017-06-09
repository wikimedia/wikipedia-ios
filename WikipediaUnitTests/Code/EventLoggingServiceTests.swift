import Foundation
import WMF

func makeEventLoggingService() -> EventLoggingService {
    
    let reachability = MockNetworkReachabilityManager()
    let urlSessionConfig = URLSessionConfiguration()    
    let eventLoggingService = EventLoggingService(urlSesssionConfiguration: urlSessionConfig, reachabilityManager: reachability, permanentStorageURL: nil)
    
    return eventLoggingService
    
}
