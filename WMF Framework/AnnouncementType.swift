
import Foundation

public enum AnnouncementType: String {
    case fundraising
    case survey
    case announcement
    case unknown
}

public extension WMFAnnouncement {
    var announcementType: AnnouncementType {
        
        guard let type = type else {
            return .unknown
        }
        
        return AnnouncementType(rawValue: type) ?? .unknown
    }
}
