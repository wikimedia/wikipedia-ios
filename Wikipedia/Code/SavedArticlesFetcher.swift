import Foundation
import WMF
import CocoaLumberjackSwift

//WMFLocalizedStringWithDefaultValue(@"saved-pages-image-download-error", nil, nil, @"Failed to download images for this saved page.", @"Error message shown when one or more images fails to save for offline use.")

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
    private var backgroundTaskIdentifier: UIBackgroundTaskIdentifier?
    
    private let articleCacheController: ArticleCacheController
    private let spotlightManager: WMFSavedPageSpotlightManager
    
    private var isRunning = false
    private var isUpdating = false
    
    private var currentlyFetchingArticleKeys: [String] = []
    
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
        } catch(let error) {
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
    
    @objc func _update() {
        if isUpdating || !isRunning {
            updateCountOfFetchesInProcess()
            return
        }
        
        isUpdating = true
        
        let endBackgroundTask = {
            if let backgroundTaskIdentifier = self.backgroundTaskIdentifier {
                UIApplication.shared.endBackgroundTask(backgroundTaskIdentifier)
                self.backgroundTaskIdentifier = nil
            }
        }
        
        if backgroundTaskIdentifier == nil {
            self.backgroundTaskIdentifier = UIApplication.shared.beginBackgroundTask(withName: "SavedArticlesFetch", expirationHandler: {
                self.cancelAllRequests()
                self.stop()
                endBackgroundTask()
            })
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
        } catch (let error) {
            DDLogError("Error fetching next article to download: \(error)");
        }
        
        let updateAgain = {
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(100)) {
                self.isUpdating = false
                self.update()
            }
        }
        
        if let articleURL = article?.url,
            let articleKey = article?.key,
            let articleObjectID = article?.objectID {
            
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
                        DDLogInfo("Successfully saved all items for \(articleKey), itemKeyCount: \(itemKeys.count)")
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
            } catch (let error) {
                DDLogError("Error fetching downloaded unsaved articles: \(error)");
            }
            
            let noArticleToDeleteCompletion = {
                self.isUpdating = false
                self.updateCountOfFetchesInProcess()
                endBackgroundTask()
            }
            
            if let articleToDelete = articleToDelete {
                
                guard let articleKey = articleToDelete.key else {
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
                            DDLogInfo("Successfully removed all items for \(articleKey)")
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
    
    func didFetchArticle(with managedObjectID: NSManagedObjectID) {
        operateOnArticle(with: managedObjectID) { (article) in
            article.isDownloaded = true
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
        } catch (let error) {
            DDLogError("Error saving after saved articles fetch: \(error)");
        }
    }
}

@objc(WMFMobileViewToMobileHTMLMigrationController)
class MobileViewToMobileHTMLMigrationController: NSObject {
    private let dataStore: MWKDataStore
    private var backgroundTaskIdentifier: UIBackgroundTaskIdentifier?
    
    @objc init(dataStore: MWKDataStore) {
        self.dataStore = dataStore
        super.init()
    }
    
    @objc func start() {
        convertOneArticleIfNecessary()
    }
    
    @objc func stop() {
        if let backgroundTaskIdentifier = backgroundTaskIdentifier {
            UIApplication.shared.endBackgroundTask(backgroundTaskIdentifier)
            self.backgroundTaskIdentifier = nil
        }
    }
    
    private func convertOneArticleIfNecessary() {
        assert(Thread.isMainThread)
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(_convertOneArticleIfNecessary), object: nil)
        perform(#selector(_convertOneArticleIfNecessary), with: nil, afterDelay: 0.5)
    }
    
    private lazy var isConversionFromMobileViewNeededPredicateString = {
        return "isConversionFromMobileViewNeeded == TRUE"
    }()
    
    private lazy var conversionsNeededCountFetchRequest: NSFetchRequest<WMFArticle> = {
        let request = WMFArticle.fetchRequest()
        request.includesSubentities = false
        request.predicate = NSPredicate(format: isConversionFromMobileViewNeededPredicateString)
        return request 
    }()

    private lazy var mostRecentArticleToBeConvertedFetchRequest: NSFetchRequest<WMFArticle> = {
        let request = WMFArticle.fetchRequest()
        request.predicate = NSPredicate(format: isConversionFromMobileViewNeededPredicateString)
        request.sortDescriptors = [NSSortDescriptor(key: "savedDate", ascending: false)]
        request.fetchLimit = 1
        request.propertiesToFetch = []
        return request
    }()

    @objc private func _convertOneArticleIfNecessary() {
        if backgroundTaskIdentifier == nil {
            backgroundTaskIdentifier = UIApplication.shared.beginBackgroundTask(withName: "MobileviewToMobileHTMLConverter", expirationHandler: stop)
        }
        let moc = dataStore.viewContext
        var article: WMFArticle?
        do {
            article = try moc.fetch(mostRecentArticleToBeConvertedFetchRequest).first
        } catch (let error) {
            DDLogError("No articles to convert: \(error)")
        }

        guard let nonNilArticle = article else {
            stop()
            // No more articles to convert, ensure the legacy folder is deleted
            DispatchQueue.global(qos: .background).async {
                self.dataStore.removeAllLegacyArticleData()
            }
            return
        }
        
        dataStore.migrateMobileviewToMobileHTMLIfNecessary(article: nonNilArticle) { error in
            do {
                guard try moc.count(for: self.conversionsNeededCountFetchRequest) > 0 else {
                    // No more articles to convert, ensure the legacy folder is deleted
                    DispatchQueue.global(qos: .background).async {
                        self.dataStore.removeAllLegacyArticleData()
                    }
                    self.stop()
                    return
                }
                self.convertOneArticleIfNecessaryAgain()
            } catch(let error) {
                DDLogError("Error counting number of article to be converted: \(error)")
                self.stop()
            }
        }
    }

    private func convertOneArticleIfNecessaryAgain() {
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) {
            self.convertOneArticleIfNecessary()
        }
    }
}
