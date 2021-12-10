
import Foundation

/// Base class for operations that deal with fetching and persisting user notifications. Operation will recursively call the next page, with overrideable hooks to adjust this behavior.
class RemoteNotificationsPagingOperation: RemoteNotificationsOperation {
    
    private let needsCrossWikiSummary: Bool
    private(set) var crossWikiSummaryNotification: RemoteNotificationsAPIController.NotificationsResult.Notification?
    
    required init(project: RemoteNotificationsProject, apiController: RemoteNotificationsAPIController, modelController: RemoteNotificationsModelController, needsCrossWikiSummary: Bool) {
        self.needsCrossWikiSummary = needsCrossWikiSummary
        super.init(project: project, apiController: apiController, modelController: modelController)
    }
    
    required init(project: RemoteNotificationsProject, apiController: RemoteNotificationsAPIController, modelController: RemoteNotificationsModelController) {
        fatalError("init(project:apiController:modelController:) has not been implemented")
    }
    
    //MARK: Overridable hooks
    
    ///Boolean logic for allowing operation execution. Override to add any validation before executing this operation.
    var shouldExecute: Bool {
        return true
    }
    
    /// Hook to exit early from recursively paging and persisting the API response. This is called right before the next page is fetched from the API. This value will take priority even if last response indicates that there are additional pages to fetch.
    /// - Parameter lastNotification: The last notification returned from the previous response
    /// - Returns: Boolean flag indicating recursive paging should continue or not in this operation.
    func shouldContinueToPage(lastNotification: RemoteNotificationsAPIController.NotificationsResult.Notification) -> Bool {
        return true
    }

    /// Hook that is called when the last page of notifications has been fetched and saved locally. Do any additional cleanup here.
    func didFetchAndSaveAllPages() {
        
    }

    /// Hook that is called when we are about to fetch and persist a new page from the API.
    /// - Parameter newContinueId: Continue Id the operation will send in the next API call.
    func willFetchAndSaveNewPage(newContinueId: String) {
        
    }
    
    /// Override to provide an initial continue Id to send into the first API call
    var initialContinueId: String? {
        return nil
    }
    
    /// Override to allow operation to page through a filtered list (read, unread, etc.)
    var filter: RemoteNotificationsAPIController.Query.Filter {
        return .none
    }
    
    //MARK: General Fetch and Save functionality
    
    override func execute() {
        
        guard shouldExecute else {
            finish()
            return
        }
        
        recursivelyFetchAndSaveNotifications(continueId: initialContinueId)
    }
    
    private func recursivelyFetchAndSaveNotifications(continueId: String? = nil) {
        apiController.getAllNotifications(from: project, needsCrossWikiSummary: needsCrossWikiSummary, filter: filter, continueId: continueId) { [weak self] result, error in
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
            
            var fetchedNotificationsToPersist = fetchedNotifications
            if self.needsCrossWikiSummary {
                
                let notificationIsSummaryType: (RemoteNotificationsAPIController.NotificationsResult.Notification) -> Bool = { notification in
                    notification.id == "-1" && notification.type == "foreign"
                }
                
                let crossWikiSummaryNotification = fetchedNotificationsToPersist.first(where: notificationIsSummaryType)
                self.crossWikiSummaryNotification = crossWikiSummaryNotification
                
                fetchedNotificationsToPersist = fetchedNotifications.filter({ notification in
                    !notificationIsSummaryType(notification)
                })
            }

            do {
                let backgroundContext = self.modelController.newBackgroundContext()
                try self.modelController.createNewNotifications(moc: backgroundContext, notificationsFetchedFromTheServer: Set(fetchedNotificationsToPersist), completion: { [weak self] in

                    guard let self = self else {
                        return
                    }

                    guard let newContinueId = result?.continueId,
                          newContinueId != continueId,
                          self.shouldContinueToPage(lastNotification: lastNotification) else {
                        self.didFetchAndSaveAllPages()
                        self.finish()
                        return
                    }

                    self.willFetchAndSaveNewPage(newContinueId: newContinueId)
                    self.recursivelyFetchAndSaveNotifications(continueId: newContinueId)
                })
            } catch {
                self.finish(with: error)
            }
        }
    }
}
