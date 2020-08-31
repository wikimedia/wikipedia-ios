
import Foundation

class EPCStorageManager: EPCStorageManaging {

    private let legacyEventLoggingService: EventLoggingService
    
    public static let shared: EPCStorageManager? = {
        guard let legacyEventLoggingService = EventLoggingService.shared else {
            DDLogError("EPCStorageManager: Unable to get pull legacy EventLoggingService instance for instantiating EPCStorageManager")
            return nil
        }
        
        return EPCStorageManager(legacyEventLoggingService: legacyEventLoggingService)
    }()
    
    public init?(legacyEventLoggingService: EventLoggingService) {
        self.legacyEventLoggingService = legacyEventLoggingService
    }
    
    //MARK: EPCStorageManaging
    
    var installID: String? {
        return legacyEventLoggingService.appInstallID
    }
    
    var sharingUsageData: Bool {
        return legacyEventLoggingService.isEnabled
    }
}
