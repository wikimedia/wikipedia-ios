import CocoaLumberjackSwift

public enum RemoteNotificationsOperationsError: Error {
    case failurePullingAppLanguage
    case failureCreatingAppLanguagePagingOperation
    case alreadyImportingOrRefreshing
}

class RemoteNotificationsOperationsController: NSObject {
    private let apiController: RemoteNotificationsAPIController
    private let modelController: RemoteNotificationsModelController
    private let operationQueue: OperationQueue
    private let languageLinkController: MWKLanguageLinkController
    private let authManager: WMFAuthenticationManager
    private var isImporting = false
    private var isRefreshing = false
    private var importingCompletionBlocks: [(RemoteNotificationsOperationsError?) -> Void] = []

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
    
    /// Kicks off operations to fetch and persist read and unread history of notifications from app languages, Commons, and Wikidata. Designed to fully import once per installation. Will not attempt if import is already in progress. Must be called from main thread.
    /// - Parameter completion: Block to run once operations have completed. Dispatched to main thread.
    func importNotificationsIfNeeded(_ completion: @escaping (RemoteNotificationsOperationsError?) -> Void) {
        
        assert(Thread.isMainThread)
        
        importingCompletionBlocks.append(completion)
        
        //Purposefully not calling completion block here, because we are tracking it in line above. It will be called when
        //currently running operation completes.
        guard !isImporting else {
            return
        }
        
        isImporting = true
        
        kickoffPagingOperations(operationType: RemoteNotificationsImportOperation.self) { [weak self] error in
            DispatchQueue.main.async {
                self?.isImporting = false
                self?.importingCompletionBlocks.forEach { completionBlock in
                    completionBlock(error)
                }

                self?.importingCompletionBlocks.removeAll()
            }
        }
    }
    
    /// Kicks off operations to fetch and persist any new read and unread notifications from app languages, Commons, and Wikidata. Will not attempt if importing or refreshing is already in progress. Must be called from main thread.
    /// - Parameter completion: Block to run once operations have completed. Dispatched to main thread.
    func refreshNotifications(_ completion: @escaping (RemoteNotificationsOperationsError?) -> Void) {
        
        assert(Thread.isMainThread)
        
        guard !isImporting && !isRefreshing else {
            completion(.alreadyImportingOrRefreshing)
            return
        }
        
        isRefreshing = true
        
        kickoffPagingOperations(operationType: RemoteNotificationsRefreshOperation.self) { [weak self] error in
            DispatchQueue.main.async {
                self?.isRefreshing = false
                completion(error)
            }
        }
    }
    
    /// Method that instantiates the appropriate paging operations for fetching & persisting remote notifications and adds them to the operation queue. Must be called from main thread.
    /// - Parameters:
    ///   - operationType: RemoteNotificationsPagingOperation class to instantiate. Can be an Import or Refresh type.
    ///   - completion: Block to run after operations have completed.
    private func kickoffPagingOperations(operationType: RemoteNotificationsPagingOperation.Type, completion: @escaping (RemoteNotificationsOperationsError?) -> Void) {
        
        let preferredLanguages = languageLinkController.preferredLanguages
   
        guard let appLanguage = languageLinkController.appLanguage else {
            completion(.failurePullingAppLanguage)
            return
        }
        
        let primaryLanguageProject = RemoteNotificationsProject.wikipedia(appLanguage.languageCode, appLanguage.localizedName, appLanguage.languageVariantCode)
        let nonPrimaryLanguages = preferredLanguages.filter { $0.languageCode != appLanguage.languageCode }

        var nonPrimaryProjects: [RemoteNotificationsProject] = nonPrimaryLanguages.map { .wikipedia($0.languageCode, $0.localizedName, $0.languageVariantCode) }
        nonPrimaryProjects.append(.commons)
        nonPrimaryProjects.append(.wikidata)
        
        let nonPrimaryOperations: [RemoteNotificationsPagingOperation] = nonPrimaryProjects.map { operationType.init(project: $0, apiController: self.apiController, modelController: modelController, needsCrossWikiSummary: false) }
        
        let completionOperation: BlockOperation
        
        //supremely hacky way of handling unauthenticated responses from these operations
        if let firstNonPrimaryOperation = nonPrimaryOperations.first {
            
            completionOperation = BlockOperation {
                if let error = firstNonPrimaryOperation.error as? RemoteNotificationsAPIController.ResultError,
                   error.code == "login-required" {
                    self.attemptReauthenticateFromError(error) { result in
                        switch result {
                        case .success:
                            self.kickoffPagingOperations(operationType: operationType, completion: completion)
                        default:
                            completion(nil)
                        }
                    }
                }
                completion(nil)
            }
            
        } else {
            completionOperation = BlockOperation {
                completion(nil)
            }
        }
        
        
        guard let primaryLanguageOperation = primaryLanguageOperation(primaryLanguageProject: primaryLanguageProject, nonPrimaryProjects: nonPrimaryProjects, operationType: operationType, completionOperation: completionOperation) else {
            completion(.failureCreatingAppLanguagePagingOperation)
            return
        }
        
        let finalListOfOperations = nonPrimaryOperations + [primaryLanguageOperation]
        
        for operation in finalListOfOperations {
            completionOperation.addDependency(operation)
        }
        
        self.operationQueue.addOperations(finalListOfOperations + [completionOperation], waitUntilFinished: false)
    }
    
    private func attemptReauthenticateFromError(_ error: Error, completion: @escaping (Result<Void, Error>) -> Void) {
        
        if let error = error as? RemoteNotificationsAPIController.ResultError,
           let errorCode = error.code,
            errorCode == "login-required" {
            self.authManager.loginWithSavedCredentials { result in
                switch result {
                case .success:
                    completion(.success(()))
                default:
                    completion(.failure(error))
                }
            }
            return
        }
        
        completion(.failure(error))
    }
    
    private func primaryLanguageOperation(primaryLanguageProject: RemoteNotificationsProject, nonPrimaryProjects: [RemoteNotificationsProject], operationType: RemoteNotificationsPagingOperation.Type, completionOperation: Operation) -> RemoteNotificationsPagingOperation? {
        
        let primaryLanguageOperation = operationType.init(project: primaryLanguageProject, apiController: self.apiController, modelController: modelController, needsCrossWikiSummary: true)
        primaryLanguageOperation.completionBlock = { [weak self] in
            
            guard let self = self else {
                return
            }
            
            guard let crossWikiSummary = primaryLanguageOperation.crossWikiSummaryNotification,
                  let crossWikiSources = crossWikiSummary.sources else {
                return
            }
            
            //extract new projects from summary object that aren't already queued up to be fetched from app languages + wikidata & commons
            let crossWikiProjects = crossWikiSources.keys.compactMap { RemoteNotificationsProject(apiIdentifier: $0, languageLinkController: self.languageLinkController) }
            
            let existingProjectIdentifiers = ([primaryLanguageProject] + nonPrimaryProjects).map { $0.notificationsApiWikiIdentifier }
            
            let finalCrossWikiProjects = crossWikiProjects.filter {
                
                return !existingProjectIdentifiers.contains($0.notificationsApiWikiIdentifier)
                
            }

            let crossWikiOperations = finalCrossWikiProjects.map { RemoteNotificationsRefreshCrossWikiOperation(project: $0, apiController: self.apiController, modelController: self.modelController, needsCrossWikiSummary: false) }

            
            for crossWikiOperation in crossWikiOperations {
                completionOperation.addDependency(crossWikiOperation)
                self.operationQueue.addOperation(crossWikiOperation)
            }
        }
        
        return primaryLanguageOperation
    }
    
    func markAsReadOrUnread(identifierGroups: Set<RemoteNotification.IdentifierGroup>, shouldMarkRead: Bool, languageLinkController: MWKLanguageLinkController) {
        
        //sort identifier groups into dictionary keyed by wiki
        let requestDictionary: [String: Set<RemoteNotification.IdentifierGroup>] = identifierGroups.reduce([String: Set<RemoteNotification.IdentifierGroup>]()) { partialResult, identifierGroup in

            var result = partialResult
            guard let wiki = identifierGroup.wiki else {
                return result
            }
            
            result[wiki, default: Set<RemoteNotification.IdentifierGroup>()].insert(identifierGroup)

            return result
        }
        
        //turn into array of operations
        let operations: [RemoteNotificationsMarkReadOrUnreadOperation] = requestDictionary.compactMap { element in
            
            let wiki = element.key
            guard let project = RemoteNotificationsProject(apiIdentifier: wiki, languageLinkController: languageLinkController) else {
                return nil
            }

            return RemoteNotificationsMarkReadOrUnreadOperation(project: project, apiController: apiController, modelController: modelController, identifierGroups: identifierGroups, shouldMarkRead: shouldMarkRead)
        }
        
        //MAYBETODO: should we make sure this chunk of operations and mark all chunk of operations happens serially?
        operationQueue.addOperations(operations, waitUntilFinished: false)
    }
    
    func markAllAsRead(languageLinkController: MWKLanguageLinkController) {
        assert(Thread.isMainThread)
        
        let wikisWithUnreadNotifications = modelController.distinctWikisWithUnreadNotifications()
        let projects = wikisWithUnreadNotifications.compactMap { RemoteNotificationsProject(apiIdentifier: $0, languageLinkController: self.languageLinkController) }

        let operations = projects.map { RemoteNotificationsMarkAllAsReadOperation(project: $0, apiController: self.apiController, modelController: self.modelController) }
        
        //MAYBETODO: should we make sure this chunk of operations and mark as read or unread chunk of operations happens serially?
        self.operationQueue.addOperations(operations, waitUntilFinished: false)
    }
}
