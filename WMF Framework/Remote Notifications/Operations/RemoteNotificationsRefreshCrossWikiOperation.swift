import Foundation

class RemoteNotificationsRefreshCrossWikiGroupOperation: RemoteNotificationsOperation, @unchecked Sendable {
    
    enum CrossWikiGroupError: LocalizedError {
        case individualErrors([Error])
        
        var errorDescription: String? {
            
            switch self {
            case .individualErrors(let errors):
                if let firstError = errors.first {
                    return (firstError as NSError).alertMessage()
                }
            }
            
            return CommonStrings.genericErrorDescription
            
        }
    }
    
    var crossWikiSummaryNotification: RemoteNotificationsAPIController.NotificationsResult.Notification?
    
    private let internalQueue = OperationQueue()
    private let finishingOperation = BlockOperation(block: {})
    
    private let appLanguageProject: WikimediaProject
    private let secondaryProjects: [WikimediaProject]
    private let languageLinkController: MWKLanguageLinkController
    
    init(appLanguageProject: WikimediaProject, secondaryProjects: [WikimediaProject], languageLinkController: MWKLanguageLinkController, apiController: RemoteNotificationsAPIController, modelController: RemoteNotificationsModelController) {
        self.appLanguageProject = appLanguageProject
        self.secondaryProjects = secondaryProjects
        self.languageLinkController = languageLinkController
        super.init(apiController: apiController, modelController: modelController)
    }
    
    required init(apiController: RemoteNotificationsAPIController, modelController: RemoteNotificationsModelController) {
        fatalError("init(apiController:modelController:) has not been implemented")
    }
    
    override func execute() {
        
        let crossWikiOperations = crossWikiOperations()
        for crossWikiOperation in crossWikiOperations {
            finishingOperation.addDependency(crossWikiOperation)
        }
        
        finishingOperation.completionBlock = {
            let errors = crossWikiOperations.compactMap { $0.error }
            if errors.count > 0 {
                self.finish(with: CrossWikiGroupError.individualErrors(errors))
            } else {
                self.finish()
            }
        }
        
        internalQueue.addOperations(crossWikiOperations + [finishingOperation], waitUntilFinished: false)
    }
    
    override func cancel() {
        internalQueue.cancelAllOperations()
        super.cancel()
    }
    
    private func crossWikiOperations() -> [RemoteNotificationsRefreshCrossWikiOperation] {
        
        guard let crossWikiSummary = crossWikiSummaryNotification,
              let crossWikiSources = crossWikiSummary.sources else {
            return []
        }
        
        let crossWikiProjects = crossWikiSources.keys.compactMap { WikimediaProject(notificationsApiIdentifier: $0, languageLinkController: languageLinkController) }
        
        // extract new projects from summary object that aren't already queued up to be fetched as an app language or secondary operation
        let filteredCrossWikiProjects = crossWikiProjects.filter { !([appLanguageProject] + secondaryProjects).contains($0) }

        return filteredCrossWikiProjects.map { RemoteNotificationsRefreshCrossWikiOperation(project: $0, apiController: self.apiController, modelController: self.modelController, needsCrossWikiSummary: false)}
    }
}

class RemoteNotificationsRefreshCrossWikiOperation: RemoteNotificationsPagingOperation, @unchecked Sendable {
    
    override var filter: RemoteNotificationsAPIController.Query.Filter {
        return .unread
    }
    
}
