
import Foundation


class RemoteNotificationsRefreshOperation: RemoteNotificationsOperation {
    
    private let project: RemoteNotificationsProject
    private let cookieDomain: String
    
    init(with apiController: RemoteNotificationsAPIController, modelController: RemoteNotificationsModelController, project: RemoteNotificationsProject, cookieDomain: String) {
        self.project = project
        self.cookieDomain = cookieDomain
        super.init(with: apiController, modelController: modelController)
    }
    
    override func execute() {
        fetchNewNotifications()
    }
    
    private func fetchNewNotifications(continueId: String? = nil) {
        
        apiController.getAllNotifications(from: project, continueId: continueId) { [weak self] result, error in
            
            guard let self = self else {
                return
            }
            
            if let error = error {
                self.finish(with: error)
                return
            }

            guard let fetchedNotifications = result?.list else {
                self.finish(with: RequestError.unexpectedResponse)
                return
            }
            
            guard let lastNotification = fetchedNotifications.last else {
                //Empty notifications list so nothing to import. Exit early.
                self.finish()
                return
            }
            
            let backgroundContext = self.modelController.newBackgroundContext()
            let shouldContinueToPage = self.shouldContinueToPage(moc: backgroundContext, lastNotification: lastNotification)

            do {
                try self.modelController.createNewNotifications(moc: backgroundContext, notificationsFetchedFromTheServer: Set(fetchedNotifications), completion: { [weak self] in

                    guard let self = self else {
                        return
                    }

                    guard let newContinueId = result?.continueId,
                          newContinueId != continueId,
                          shouldContinueToPage == true else {
                        self.finish()
                        return
                    }

                    self.fetchNewNotifications(continueId: newContinueId)
                })
            } catch {
                self.finish(with: error)
            }
        }
    }
    
    private func shouldContinueToPage(moc: NSManagedObjectContext, lastNotification: RemoteNotificationsAPIController.NotificationsResult.Notification) -> Bool {
        
        var shouldContinueToPage = true
        
        moc.performAndWait {
            
            //Is last (i.e. most recent) notification already in the database? If so, don't continue to page.
            let fetchRequest: NSFetchRequest<RemoteNotification> = RemoteNotification.fetchRequest()
            fetchRequest.fetchLimit = 1
            let predicate = NSPredicate(format: "key == %@", lastNotification.key)
            fetchRequest.predicate = predicate
            
            let result = try? moc.fetch(fetchRequest)
            if result?.first != nil {
                shouldContinueToPage = false
            }
        }
        
        return shouldContinueToPage
    }
}
