import Foundation
import WMF
import CocoaLumberjackSwift

// WMFLocalizedStringWithDefaultValue(@"saved-pages-image-download-error", nil, nil, @"Failed to download images for this saved page.", @"Error message shown when one or more images fails to save for offline use.")

@objc(WMFSavedArticlesFetcher)
final class SavedArticlesFetcher: NSObject {
    @objc static let saveToDiskDidFail = NSNotification.Name("SaveToDiskDidFail")
    @objc static let saveToDiskDidFailErrorKey = "error"
    @objc static let saveToDiskDidFailArticleURLKey = "articleURL"
    
    @objc dynamic var progress: Progress = Progress()
    private var countOfFetchesInProcess: Int64 = 0 {
        didSet {
            updateProgress(with: countOfFetchesInProcess, oldValue: oldValue)
        }
    }
    
    private let dataStore: MWKDataStore
    private var backgroundTaskIdentifier: UIBackgroundTaskIdentifier = UIBackgroundTaskIdentifier.invalid
    
    private let articleCacheController: ArticleCacheController
    private let spotlightManager: WMFSavedPageSpotlightManager
    
    private var isRunning = false
    private var isUpdating = false
    
    private var currentlyFetchingArticleKeys: [String] = []

    /// Start times of recent downloads. Used to keep background downloads under the per-user API budget.
    private var recentDownloadStartDates: [Date] = []
    private var consecutiveServerBusyCount = 0
    
    @objc init?(dataStore: MWKDataStore) {
        self.dataStore = dataStore
        self.articleCacheController = dataStore.cacheController.articleCache

        spotlightManager = WMFSavedPageSpotlightManager(dataStore: dataStore)
        
        super.init()
        
        resetProgress()
        updateCountOfFetchesInProcess()
    }
    
    @objc func start() {
        self.isRunning = true
        observeSavedPages()
    }
    
    @objc func stop() {
        self.isRunning = false
        unobserveSavedPages()
    }

    // MARK: - API budget

    // Wikimedia rate limits are per user and per minute (200 req/min for most readers).
    // One saved article costs about five API calls plus images. Twelve articles per minute
    // leaves most of the budget to what the user does in the foreground.
    static let maximumDownloadsPerMinute = 12
    static let downloadBudgetWindow: TimeInterval = 60

    static let defaultServerBusyCooldown: TimeInterval = 60
    static let maximumServerBusyCooldown: TimeInterval = 15 * 60
    static let minimumServerBusyCooldown: TimeInterval = 5

    /// Seconds to wait before the next download slot, or nil when a slot is free now.
    static func delayUntilNextDownloadSlot(startDates: [Date], now: Date, limit: Int = maximumDownloadsPerMinute) -> TimeInterval? {
        let windowStart = now.addingTimeInterval(-downloadBudgetWindow)
        let recent = startDates.filter { $0 > windowStart }
        guard recent.count >= limit, let oldest = recent.min() else {
            return nil
        }
        return oldest.addingTimeInterval(downloadBudgetWindow).timeIntervalSince(now)
    }

    /// Cooldown after a 429 or 503. Retry-After is the base when the server sends it. Each consecutive failure doubles the wait.
    static func serverBusyCooldown(retryAfter: TimeInterval?, consecutiveFailures: Int) -> TimeInterval {
        let base = retryAfter ?? defaultServerBusyCooldown
        let multiplier = pow(2.0, Double(max(0, consecutiveFailures - 1)))
        return min(max(base * multiplier, minimumServerBusyCooldown), maximumServerBusyCooldown)
    }

    func stopAndRestartAfterServerBusy(retryAfter: TimeInterval?) {
        assert(Thread.isMainThread)
        consecutiveServerBusyCount += 1
        let cooldown = Self.serverBusyCooldown(retryAfter: retryAfter, consecutiveFailures: consecutiveServerBusyCount)
        DDLogWarn("SavedArticlesFetcher: server busy, pausing downloads for \(Int(cooldown))s (failure #\(consecutiveServerBusyCount))")
        stop()
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(restartAfterServerBusyCooldown), object: nil)
        perform(#selector(restartAfterServerBusyCooldown), with: nil, afterDelay: cooldown)
    }

    @objc private func restartAfterServerBusyCooldown() {
        start()
        update()
    }

    /// Reschedules the next download when the server asked the app to wait or the per-minute budget is spent. Returns true when a wait was scheduled.
    private func deferUpdateIfOverBudget() -> Bool {
        let now = Date()
        var delay: TimeInterval?
        if let pauseUntil = dataStore.session.serverBusyPauseUntil {
            delay = pauseUntil.timeIntervalSince(now)
        } else if let slotDelay = Self.delayUntilNextDownloadSlot(startDates: recentDownloadStartDates, now: now) {
            delay = slotDelay
        }
        guard let delay, delay > 0 else {
            return false
        }
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(_update), object: nil)
        perform(#selector(_update), with: nil, afterDelay: delay + 0.1)
        return true
    }

    private func noteDownloadStarted() {
        let windowStart = Date().addingTimeInterval(-Self.downloadBudgetWindow)
        recentDownloadStartDates = recentDownloadStartDates.filter { $0 > windowStart }
        recentDownloadStartDates.append(Date())
    }
}

private extension SavedArticlesFetcher {
    func updateCountOfFetchesInProcess() {
        guard let count = calculateCountOfArticlesToFetch() else {
            return
        }
        countOfFetchesInProcess = count
    }
    
    func updateProgress(with newValue: Int64, oldValue: Int64) {
        progress.totalUnitCount = max(progress.totalUnitCount, newValue)
        let completedUnits = progress.totalUnitCount - newValue
        progress.completedUnitCount = completedUnits
        guard newValue == 0 else {
            return
        }
        resetProgress()
    }
    
    func resetProgress() {
        progress = Progress.discreteProgress(totalUnitCount: -1)
    }
    
    private var articlesToFetchPredicate: NSPredicate {
        let now = NSDate()
        return NSPredicate(format: "savedDate != NULL && isDownloaded != YES && (downloadRetryDate == NULL || downloadRetryDate < %@)", now)
    }
    
    func calculateCountOfArticlesToFetch() -> Int64? {
        assert(Thread.isMainThread)
        
        let moc = dataStore.viewContext
        let request = WMFArticle.fetchRequest()
        request.includesSubentities = false
        request.predicate = articlesToFetchPredicate
        
        do {
            let count = try moc.count(for: request)
            return (count >= 0) ? Int64(count) : nil
        } catch let error {
            DDLogError("Error counting number of article to be downloaded: \(error)")
            return nil
        }
    }
    
    func observeSavedPages() {
        NotificationCenter.default.addObserver(self, selector: #selector(articleWasUpdated(_:)), name: NSNotification.Name.WMFArticleUpdated, object: nil)
        // WMFArticleUpdatedNotification aren't coming through when the articles are created from a background sync, so observe syncDidFinish as well to download articles synced down from the server
        NotificationCenter.default.addObserver(self, selector: #selector(syncDidFinish), name: ReadingListsController.syncDidFinishNotification, object: nil)
    }
    
    @objc func articleWasUpdated(_ note: Notification) {
        update()
    }
    
    @objc func syncDidFinish(_ note: Notification) {
        update()
    }
    
    func unobserveSavedPages() {
        NotificationCenter.default.removeObserver(self)
    }
    
    func cancelAllRequests() {
        for articleKey in currentlyFetchingArticleKeys {
            articleCacheController.cancelTasks(groupKey: articleKey)
        }
    }
    
    func update() {
        assert(Thread.isMainThread)
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(_update), object: nil)
        perform(#selector(_update), with: nil, afterDelay: 0.5)
    }
    
    private func startBackgroundTask(expirationHandler: @escaping () -> Void) {
        guard backgroundTaskIdentifier == UIBackgroundTaskIdentifier.invalid else {
            return
        }
        
        backgroundTaskIdentifier = UIApplication.shared.beginBackgroundTask(withName: "SavedArticlesFetch", expirationHandler: { [weak self] in
            expirationHandler()
            self?.endBackgroundTask()
        })
    }
    
    private func endBackgroundTask() {
        
        guard backgroundTaskIdentifier != UIBackgroundTaskIdentifier.invalid else {
            return
        }
        
        let backgroundTaskIdentifier = self.backgroundTaskIdentifier
        self.backgroundTaskIdentifier = UIBackgroundTaskIdentifier.invalid
        UIApplication.shared.endBackgroundTask(backgroundTaskIdentifier)
    }
    
    @objc func _update() {
        if isUpdating || !isRunning {
            updateCountOfFetchesInProcess()
            return
        }

        if deferUpdateIfOverBudget() {
            return
        }
        
        isUpdating = true
        
        startBackgroundTask {
            self.cancelAllRequests()
            self.stop()
        }
        
        assert(Thread.isMainThread)
        
        let moc = dataStore.viewContext
        let request = WMFArticle.fetchRequest()
        request.predicate = articlesToFetchPredicate
        request.sortDescriptors = [NSSortDescriptor(key: "savedDate", ascending: true)]
        request.fetchLimit = 1
        
        var article: WMFArticle?
        do {
            article = try moc.fetch(request).first
        } catch let error {
            DDLogError("Error fetching next article to download: \(error)")
        }
        
        let updateAgain = {
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(100)) {
                self.isUpdating = false
                self.endBackgroundTask()
                self.update()
            }
        }
        
        if let articleURL = article?.url,
            let articleKey = article?.key,
            let articleObjectID = article?.objectID {

            noteDownloadStarted()
            articleCacheController.add(url: articleURL, groupKey: articleKey, individualCompletion: { (itemResult) in
                switch itemResult {
                case .success:
                    break
                case .failure(let error):
                    DDLogError("Failed saving an item for \(articleKey): \(error)")
                }
            }) { (groupResult) in
                DispatchQueue.main.async {
                    switch groupResult {
                    case .success(let itemKeys):
                        DDLogDebug("Successfully saved all items for \(articleKey), itemKeyCount: \(itemKeys.count)")
                        self.didFetchArticle(with: articleObjectID)
                        self.spotlightManager.addToIndex(url: articleURL as NSURL)
                        self.updateCountOfFetchesInProcess()
                    case .failure(let error):
                        DDLogError("Failed saving items for \(articleKey): \(error)")
                        self.updateCountOfFetchesInProcess()
                        self.didFailToFetchArticle(with: articleObjectID, error: error)
                    }
                    updateAgain()
                }
            }
        } else {
            let downloadedRequest = WMFArticle.fetchRequest()
            downloadedRequest.predicate = NSPredicate(format: "savedDate == NULL && isDownloaded == YES")
            downloadedRequest.sortDescriptors = [NSSortDescriptor(key: "savedDate", ascending: true)]
            downloadedRequest.fetchLimit = 1
            
            var articleToDelete: WMFArticle?
            do {
                articleToDelete = try moc.fetch(downloadedRequest).first
            } catch let error {
                DDLogError("Error fetching downloaded unsaved articles: \(error)")
            }
            
            let noArticleToDeleteCompletion = {
                self.isUpdating = false
                self.updateCountOfFetchesInProcess()
                self.endBackgroundTask()
            }
            
            if let articleToDelete = articleToDelete {
                
                guard let articleKey = articleToDelete.key,
                      let articleURL = articleToDelete.url else {
                    noArticleToDeleteCompletion()
                    return
                }
                
                let articleObjectID = articleToDelete.objectID
                
                articleCacheController.remove(groupKey: articleKey, individualCompletion: { (itemResult) in
                    switch itemResult {
                    case .success:
                        break
                    case .failure(let error):
                        DDLogError("Failed removing item for \(articleKey): \(error)")
                    }
                }) { (groupResult) in
                    DispatchQueue.main.async {
                        switch groupResult {
                        case .success:
                            DDLogDebug("Successfully removed all items for \(articleKey)")
                            self.spotlightManager.removeFromIndex(url: articleURL as NSURL)
                        case .failure(let error):
                            DDLogError("Failed removing items for \(articleKey): \(error)")
                            break
                        }
                        // Ignoring failures to ensure the DB doesn't get stuck trying
                        // to remove a cache group that doesn't exist.
                        // TODO: Clean up these DB inconsistencies in the DatabaseHousekeeper
                        self.didRemoveArticle(with: articleObjectID)
                        self.updateCountOfFetchesInProcess()
                        updateAgain()
                    }
                }
            } else {
                noArticleToDeleteCompletion()
            }
        }
    }
    
}

// Internal (not private) for unit testing
extension SavedArticlesFetcher {
    func didFetchArticle(with managedObjectID: NSManagedObjectID) {
        consecutiveServerBusyCount = 0
        operateOnArticle(with: managedObjectID) { (article) in
            article.isDownloaded = true
            // A failure on an earlier attempt is no longer relevant — without this
            // the "Unable to sync article" label sticks forever (T431140 follow-up)
            article.error = .none
            article.downloadAttemptCount = 0
            article.downloadRetryDate = nil
        }
    }

    func didFailToFetchArticle(with managedObjectID: NSManagedObjectID, error: Error) {
        operateOnArticle(with: managedObjectID) { (article) in
            handleFailure(with: article, error: error)
        }
    }
    
    func handleFailure(with article: WMFArticle, error: Error) {
        var underlyingError: Error = error
        if let cacheError = error as? CacheControllerError {
            switch cacheError {
            case .atLeastOneItemFailedInSync(let error):
                fallthrough
            case .atLeastOneItemFailedInFileWriter(let error):
                underlyingError = error
            default:
                break
            }
        } else if let writerError = error as? ArticleCacheDBWriterError {
            switch writerError {
            case .failureFetchingMediaList(let error):
                fallthrough
            case .failureFetchingOfflineResourceList(let error):
                underlyingError = error
            case .oneOrMoreItemsFailedToMarkDownloaded(let errors):
                underlyingError = errors.first ?? error
            default:
                break
            }
        }
        DDLogError("SavedArticlesFetcher: failed to download article \(article.key ?? "unknown"): \(underlyingError)")
        if let requestError = underlyingError as? RequestError, requestError.isServerBusy {
            // Rate limited or overloaded — a global condition, not this article's fault. Pause all
            // downloading and retry the article as-is when the fetcher restarts,
            // instead of branding it with an error and escalating its backoff.
            stopAndRestartAfterServerBusy(retryAfter: requestError.retryAfter)
            return
        }
        if underlyingError is RequestError {
            article.error = .apiFailed
        } else {
            let nsError = underlyingError as NSError
            if nsError.domain == NSCocoaErrorDomain && nsError.code == NSFileWriteOutOfSpaceError {
                let userInfo = [SavedArticlesFetcher.saveToDiskDidFailErrorKey: error]
                NotificationCenter.default.post(name: SavedArticlesFetcher.saveToDiskDidFail, object: self, userInfo: userInfo)
                stop()
                article.error = .saveToDiskFailed
            } else if nsError.domain == NSURLErrorDomain {
                switch nsError.code {
                case NSURLErrorTimedOut:
                    fallthrough
                case NSURLErrorCancelled:
                    fallthrough
                case NSURLErrorCannotConnectToHost:
                    fallthrough
                case NSURLErrorCannotFindHost:
                    fallthrough
                case NSURLErrorNetworkConnectionLost:
                    fallthrough
                case NSURLErrorNotConnectedToInternet:
                    stop()
                default:
                    article.error = .apiFailed
                }
            } else {
                article.error = .apiFailed
            }
        }
        let newAttemptCount =  max(1, article.downloadAttemptCount + 1)
        article.downloadAttemptCount = newAttemptCount
        let secondsFromNowToAttempt: Int64
        // pow() exists but this feels safer than converting to/from decimal, feel free to update if you know better
        switch newAttemptCount {
        case 1:
            secondsFromNowToAttempt = 30
        case 2:
            secondsFromNowToAttempt = 900
        case 3:
            secondsFromNowToAttempt = 27000
        case 4:
            secondsFromNowToAttempt = 810000
        default:
            secondsFromNowToAttempt = 2419200 // 28 days later ☣
        }
        article.downloadRetryDate = Date(timeIntervalSinceNow: TimeInterval(integerLiteral: secondsFromNowToAttempt))
    }

    func didRemoveArticle(with managedObjectID: NSManagedObjectID) {
        operateOnArticle(with: managedObjectID) { (article) in
            article.isDownloaded = false
        }
    }
    
    func operateOnArticle(with managedObjectID: NSManagedObjectID, articleBlock: (WMFArticle) -> Void) {
        guard let article = dataStore.viewContext.object(with: managedObjectID) as? WMFArticle else {
            return
        }
        articleBlock(article)
        do {
            try dataStore.save()
        } catch let error {
            DDLogError("Error saving after saved articles fetch: \(error)")
        }
    }
}
