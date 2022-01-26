
import Foundation

class RemoteNotificationsRefreshCrossWikiOperation: RemoteNotificationsPagingOperation {
    
    override var filter: RemoteNotificationsAPIController.Query.Filter {
        return .unread
    }
    
}
