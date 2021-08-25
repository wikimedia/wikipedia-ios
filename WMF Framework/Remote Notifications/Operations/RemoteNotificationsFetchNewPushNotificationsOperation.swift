class RemoteNotificationsFetchNewPushNotificationsOperation: AsyncOperation {
    private let apiController: RemoteNotificationsAPIController
    private let languageCode: String
    private let cookieDomain: String
    private(set) var result: Result<[RemoteNotificationsAPIController.NotificationsResult.Notification], Error>?
    
    init(with apiController: RemoteNotificationsAPIController, languageCode: String, cookieDomain: String, completion: @escaping (Result<[RemoteNotificationsAPIController.NotificationsResult.Notification], Error>) -> Void) {
        self.languageCode = languageCode
        self.cookieDomain = cookieDomain
        self.apiController = apiController
        super.init()
        
        self.completionBlock = {
            completion(self.result ?? .failure(RequestError.unexpectedResponse))
        }
    }
    override func execute() {
        
        guard apiController.isAuthenticatedForCookieDomain(cookieDomain) else {
            let error = RequestError.unauthenticated
            result = .failure(error)
            self.finish(with: error)
            return
        }
        
        self.apiController.getUnreadPushNotifications(from: self.languageCode) { [weak self] result, error in
            guard let self = self else {
                return
            }
            
            if let error = error {
                self.result = .failure(error)
                self.finish(with: error)
                return
            }
            
            guard let newNotifications = result?.list else {
                let error = RequestError.unauthenticated
                self.result = .failure(error)
                self.finish(with: error)
                return
            }
            
            let cachedNotifications = self.loadCache()
            
            //Prune persisted keys of any > 1 day? ago.
            let oneDay = TimeInterval(60 * 60 * 24)
            let prunedCachedNotifications = cachedNotifications.filter { notification in
                guard let date = notification.date else {
                    return false
                }
                
                return date > Date().addingTimeInterval(-oneDay)
            }
            
            //Prune new notifications > 10mins ago.
            let tenMins = TimeInterval(60 * 10)
            let prunedNewNotifications = newNotifications.filter { notification in
                guard let date = notification.date else {
                    return false
                }
                
                return date > Date().addingTimeInterval(-tenMins)
            }
            
            //Filter out those new unread fetched notifications that are already in remaining persisted keys
            //TODO: A simple filtering via "prunedCachedNotifications.contains" didn't seem to work, so breaking it down by key. This should be cleaned up.
            let prunedCachedNotificationKeys = prunedCachedNotifications.map { $0.key }
            let prunedNewNotificationKeys = prunedNewNotifications.map { $0.key }
            let finalNotificationKeys = prunedNewNotificationKeys.filter { !prunedCachedNotificationKeys.contains($0) }
            let finalNotifications = prunedNewNotifications.filter { finalNotificationKeys.contains($0.key) }
            
            self.result = .success(finalNotifications)
            
            //Cache final notifications for next analysis.
            let newNotificationsToCache = prunedCachedNotifications + finalNotifications
            self.saveCache(Set(newNotificationsToCache))
            
            self.finish()
        }
    }
}



//Notification Service Extension Cache
//Taken from WidgetController - it may be useful to make these methods generic to reduce duplication
extension RemoteNotificationsFetchNewPushNotificationsOperation {
    
    // MARK: - Properties

    fileprivate var cacheDirectoryContainerURL: URL {
        FileManager.default.wmf_containerURL()
    }

    fileprivate var pushNotificationsCacheDataFileURL: URL {
        return cacheDirectoryContainerURL.appendingPathComponent("Push Notifications Cache").appendingPathExtension("json")
    }

    // MARK: - Push Notifications Cache

    func loadCache() -> Set<RemoteNotificationsAPIController.NotificationsResult.Notification> {
        if let data = try? Data(contentsOf: pushNotificationsCacheDataFileURL), let decodedCache = try? JSONDecoder().decode(Set<RemoteNotificationsAPIController.NotificationsResult.Notification>.self, from: data) {
            return decodedCache
        }

        return []
    }

    func saveCache(_ pushNotificationsCache: Set<RemoteNotificationsAPIController.NotificationsResult.Notification>) {
        let encoder = JSONEncoder()
        guard let encodedCache = try? encoder.encode(pushNotificationsCache) else {
            return
        }

        try? encodedCache.write(to: pushNotificationsCacheDataFileURL)
    }
}
