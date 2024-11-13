import Foundation

class RemoteNotificationsRefreshOperation: RemoteNotificationsPagingOperation, @unchecked Sendable {
    
    override func shouldContinueToPage(lastNotification: RemoteNotificationsAPIController.NotificationsResult.Notification) -> Bool {
        
        let backgroundContext = self.modelController.newBackgroundContext()
        var shouldContinueToPage = true
        backgroundContext.performAndWait {
            
            // Is last (i.e. most recent) notification already in the database? If so, don't continue to page.
            let fetchRequest = RemoteNotification.fetchRequest()
            fetchRequest.fetchLimit = 1
            let predicate = NSPredicate(format: "key == %@", lastNotification.key)
            fetchRequest.predicate = predicate
            
            let result = try? backgroundContext.fetch(fetchRequest)
            if result?.first != nil {
                shouldContinueToPage = false
            }
        }
        
        return shouldContinueToPage
    }
}
