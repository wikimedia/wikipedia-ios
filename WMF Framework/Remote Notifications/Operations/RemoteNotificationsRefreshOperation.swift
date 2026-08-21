import Foundation

class RemoteNotificationsRefreshOperation: RemoteNotificationsPagingOperation, @unchecked Sendable {
    
    override func shouldContinueToPage(lastNotification: RemoteNotificationsAPIController.NotificationsResult.Notification) -> Bool {
        
        let backgroundContext = self.modelController.newBackgroundContext()
        let lastNotificationKey = lastNotification.key
        // The SDK's generic performAndWait runs the block inline on the context's
        // queue and returns its value, so no captured var crosses a @Sendable boundary.
        return backgroundContext.performAndWait {

            // Is last (i.e. most recent) notification already in the database? If so, don't continue to page.
            let fetchRequest = RemoteNotification.fetchRequest()
            fetchRequest.fetchLimit = 1
            let predicate = NSPredicate(format: "key == %@", lastNotificationKey)
            fetchRequest.predicate = predicate

            let result = try? backgroundContext.fetch(fetchRequest)
            return result?.first == nil
        }
    }
}
