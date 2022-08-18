import CocoaLumberjackSwift

enum RemoteNotificationsOperationsError: LocalizedError {
    case failurePullingAppLanguage
    case individualErrors([Error])
    
    var errorDescription: String? {
        
        switch self {
        case .individualErrors(let errors):
            if let firstError = errors.first {
                return (firstError as NSError).alertMessage()
            }
        default:
            break
        }
        
        return CommonStrings.genericErrorDescription
    }
}

public extension Notification.Name {
    static let NotificationsCenterLoadingDidStart = Notification.Name("NotificationsCenterLoadingDidStart") // fired when notifications have begun importing or refreshing
    static let NotificationsCenterLoadingDidEnd = Notification.Name("NotificationsCenterLoadingDidEnd") // fired when notifications have ended importing or refreshing
}

class RemoteNotificationsOperationsController: NSObject {
    private let apiController: RemoteNotificationsAPIController
    private let modelController: RemoteNotificationsModelController
    private let operationQueue: OperationQueue
    private let languageLinkController: MWKLanguageLinkController
    private let authManager: WMFAuthenticationManager
    private(set) var isLoadingNotifications = false
    private var loadingNotificationsCompletionBlocks: [(Result<Void, Error>) -> Void] = []

    required init(languageLinkController: MWKLanguageLinkController, authManager: WMFAuthenticationManager, apiController: RemoteNotificationsAPIController, modelController: RemoteNotificationsModelController) {
        self.apiController = apiController
        self.modelController = modelController

        operationQueue = OperationQueue()
        
        self.languageLinkController = languageLinkController
        self.authManager = authManager
        
        super.init()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: Public
    
    /// Kicks off operations to fetch and persist read and unread history of notifications from app languages, Commons, and Wikidata, + other projects with unread notifications. Designed to automatically page and fully import once per installation, then only fetch new notifications for each project when called after that. Will not attempt if loading is already in progress. Must be called from main thread.
    /// - Parameter completion: Block to run once operations have completed. Dispatched to main thread.
    func loadNotifications(_ completion: ((Result<Void, Error>) -> Void)? = nil) {
        assert(Thread.isMainThread)
        
        if let completion = completion {
            loadingNotificationsCompletionBlocks.append(completion)
        }
        
        // Purposefully not calling completion block here, because we are tracking it in line above. It will be called when currently running loading operations complete.
        guard !isLoadingNotifications else {
            return
        }
        
        isLoadingNotifications = true
        NotificationCenter.default.post(name: Notification.Name.NotificationsCenterLoadingDidStart, object: nil)
        
        kickoffPagingOperations { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoadingNotifications = false
                self?.loadingNotificationsCompletionBlocks.forEach { completionBlock in
                    completionBlock(result)
                }

                self?.loadingNotificationsCompletionBlocks.removeAll()
                
                NotificationCenter.default.post(name: Notification.Name.NotificationsCenterLoadingDidEnd, object: nil)
            }
        }
    }
    
    func markAsReadOrUnread(identifierGroups: Set<RemoteNotification.IdentifierGroup>, shouldMarkRead: Bool, languageLinkController: MWKLanguageLinkController, completion: ((Result<Void, Error>) -> Void)? = nil) {
        assert(Thread.isMainThread)
        
        // sort identifier groups into dictionary keyed by wiki
        let requestDictionary: [String: Set<RemoteNotification.IdentifierGroup>] = identifierGroups.reduce([String: Set<RemoteNotification.IdentifierGroup>]()) { partialResult, identifierGroup in

            var result = partialResult
            guard let wiki = identifierGroup.wiki else {
                return result
            }
            
            result[wiki, default: Set<RemoteNotification.IdentifierGroup>()].insert(identifierGroup)

            return result
        }
        
        // turn into array of operations
        let operations: [RemoteNotificationsMarkReadOrUnreadOperation] = requestDictionary.compactMap { element in
            
            let wiki = element.key
            guard let project = WikimediaProject(notificationsApiIdentifier: wiki, languageLinkController: languageLinkController) else {
                return nil
            }

            return RemoteNotificationsMarkReadOrUnreadOperation(project: project, apiController: apiController, modelController: modelController, identifierGroups: identifierGroups, shouldMarkRead: shouldMarkRead)
        }
        
        let completionOperation = BlockOperation {
            DispatchQueue.main.async {
                let errors = operations.compactMap { $0.error }
                if errors.count > 0 {
                    completion?(.failure(RemoteNotificationsOperationsError.individualErrors(errors)))
                } else {
                    completion?(.success(()))
                }
            }
        }
        
        for operation in operations {
            completionOperation.addDependency(operation)
        }
        
        operationQueue.addOperations(operations + [completionOperation], waitUntilFinished: false)
    }
    
    func markAllAsRead(languageLinkController: MWKLanguageLinkController, completion: ((Result<Void, Error>) -> Void)? = nil) {
        assert(Thread.isMainThread)
        
        let wikisWithUnreadNotifications: Set<String>
        do {
            wikisWithUnreadNotifications = try modelController.distinctWikisWithUnreadNotifications()
        } catch let error {
            completion?(.failure(error))
            return
        }
        
        let projects = wikisWithUnreadNotifications.compactMap { WikimediaProject(notificationsApiIdentifier: $0, languageLinkController: self.languageLinkController) }

        let operations = projects.map { RemoteNotificationsMarkAllAsReadOperation(project: $0, apiController: self.apiController, modelController: self.modelController) }
        
        let completionOperation = BlockOperation {
            DispatchQueue.main.async {
                let errors = operations.compactMap { $0.error }
                if errors.count > 0 {
                    completion?(.failure(RemoteNotificationsOperationsError.individualErrors(errors)))
                } else {
                    completion?(.success(()))
                }
            }
        }
        
        for operation in operations {
            completionOperation.addDependency(operation)
        }
        
        self.operationQueue.addOperations(operations + [completionOperation], waitUntilFinished: false)
    }
    
    // MARK: Private
    
    /// Generates the correct paging operation (Import or Refresh) based on a project's persisted imported state.
    /// - Parameter project: WikimediaProject to evaluate
    /// - Parameter isAppLanguageProject: Boolean if this project is for the app primary language
    /// - Returns: Appropriate RemoteNotificationsPagingOperation subclass instance
    private func pagingOperationForProject(_ project: WikimediaProject, isAppLanguageProject: Bool) -> RemoteNotificationsPagingOperation {
        
        if modelController.isProjectAlreadyImported(project: project) {
            return RemoteNotificationsRefreshOperation(project: project, apiController: self.apiController, modelController: modelController, needsCrossWikiSummary: isAppLanguageProject)
        } else {
            return RemoteNotificationsImportOperation(project: project, apiController: self.apiController, modelController: modelController, needsCrossWikiSummary: isAppLanguageProject)
        }
    }
 
    private func secondaryProjects(appLanguage: MWKLanguageLink) -> [WikimediaProject] {
        
        let otherLanguages = languageLinkController.preferredLanguages.filter { $0.languageCode != appLanguage.languageCode }

        var secondaryProjects: [WikimediaProject] = otherLanguages.map { .wikipedia($0.languageCode, $0.localizedName, $0.languageVariantCode) }
        secondaryProjects.append(.commons)
        secondaryProjects.append(.wikidata)
        
        return secondaryProjects
    }
    
    /// Method that instantiates the appropriate paging operations for fetching & persisting remote notifications and adds them to the operation queue. Must be called from main thread.
    /// - Parameters:
    ///   - completion: Block to run after operations have completed.
    private func kickoffPagingOperations(completion: @escaping (Result<Void, Error>) -> Void) {
        assert(Thread.isMainThread)
        
        guard let appLanguage = languageLinkController.appLanguage else {
            completion(.failure(RemoteNotificationsOperationsError.failurePullingAppLanguage))
            return
        }
        
        let appLanguageProject = WikimediaProject.wikipedia(appLanguage.languageCode, appLanguage.localizedName, appLanguage.languageVariantCode)
        let secondaryProjects = secondaryProjects(appLanguage: appLanguage)
        
        // basic operations first - primary language then secondary (languages, commons & wikidata)
        let appLanguageOperation = pagingOperationForProject(appLanguageProject, isAppLanguageProject: true)
        let secondaryOperations = secondaryProjects.map { project in
            pagingOperationForProject(project, isAppLanguageProject: false)
        }
        
        // BEGIN: chained cross wiki operations
        // this generates additional API calls to fetch extra unread messages by inspecting the app language operation's cross wiki summary notification object in its response
        let crossWikiGroupOperation = RemoteNotificationsRefreshCrossWikiGroupOperation(appLanguageProject: appLanguageProject, secondaryProjects: secondaryProjects, languageLinkController: languageLinkController, apiController: apiController, modelController: modelController)
        let crossWikiAdapterOperation = BlockOperation { [weak crossWikiGroupOperation] in
            crossWikiGroupOperation?.crossWikiSummaryNotification = appLanguageOperation.crossWikiSummaryNotification
        }
        crossWikiAdapterOperation.addDependency(appLanguageOperation)
        crossWikiGroupOperation.addDependency(crossWikiAdapterOperation)
        // END: chained cross wiki operations

        // BEGIN: chained reauthentication operations
        // these will ask the authManager to reauthenticate if the app language operation has an unauthenticaated error code in it's response
        // then it will cancel existing operations running and recursively call kickoffPagingOperations again
        let reauthenticateOperation = RemoteNotificationsReauthenticateOperation(authManager: authManager)
        let reauthenticateAdapterOperation = BlockOperation { [weak reauthenticateOperation] in
            reauthenticateOperation?.appLanguageOperationError = appLanguageOperation.error
        }
        reauthenticateAdapterOperation.addDependency(appLanguageOperation)
        reauthenticateOperation.addDependency(reauthenticateAdapterOperation)
        let recursiveKickoffOperation = BlockOperation { [weak self] in

            guard let self = self else {
                return
            }

            if reauthenticateOperation.didReauthenticate {
                DispatchQueue.main.async {
                    self.operationQueue.cancelAllOperations()
                    self.kickoffPagingOperations(completion: completion)
                }
            }
        }
        recursiveKickoffOperation.addDependency(reauthenticateOperation)
        // END: chained reauthentication operations
        
        let finalListOfOperations = [appLanguageOperation, crossWikiAdapterOperation, crossWikiGroupOperation, reauthenticateAdapterOperation, reauthenticateOperation, recursiveKickoffOperation] + secondaryOperations
        
        let completionOperation = BlockOperation {
            
            let errors = finalListOfOperations.compactMap { ($0 as? AsyncOperation)?.error }
            if errors.count > 0 {
                completion(.failure(RemoteNotificationsOperationsError.individualErrors(errors)))
            } else {
                completion(.success(()))
            }
        }
        
        for operation in finalListOfOperations {
            completionOperation.addDependency(operation)
        }
        
        self.operationQueue.addOperations(finalListOfOperations + [completionOperation], waitUntilFinished: false)
    }
}
