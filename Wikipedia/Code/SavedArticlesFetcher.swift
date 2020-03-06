import Foundation
import WMF

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
        
        if let articleCacheController = ArticleCacheController.shared {
            self.articleCacheController = articleCacheController
        } else {
            return nil
        }
        
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
    
    func calculateCountOfArticlesToFetch() -> Int64? {
        assert(Thread.isMainThread)
        
        let moc = dataStore.viewContext
        let request = WMFArticle.fetchRequest()
        request.includesSubentities = false
        request.predicate = NSPredicate(format: "savedDate != NULL && isDownloaded != YES")
        
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
        request.predicate = NSPredicate(format: "savedDate != NULL && isDownloaded != YES")
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
            let articleKey = articleURL.wmf_databaseKey {
            
            articleCacheController.add(url: articleURL, groupKey: articleKey, individualCompletion: { (itemResult) in
                switch itemResult {
                case .success(let itemKey):
                    DDLogDebug("🥶successfully added \(itemKey)")
                case .failure(let error):
                    DDLogDebug("🥶failure in itemCompletion of \(articleKey): \(error)")
                }
            }) { (groupResult) in
                DispatchQueue.main.async {
                    switch groupResult {
                    case .success(let itemKeys):
                        DDLogDebug("🥶group completion: \(articleKey), itemKeyCount: \(itemKeys.count)")
                        self.didFetchArticle(with: articleKey)
                        self.spotlightManager.addToIndex(url: articleURL as NSURL)
                        self.updateCountOfFetchesInProcess()
                    case .failure(let error):
                        DDLogDebug("🥶failure in groupCompletion of \(articleKey): \(error)")
                        self.updateCountOfFetchesInProcess()
                        self.didFailToFetchArticle(with: articleKey, error: error)
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
                
                guard let articleKey = articleToDelete.url?.wmf_databaseKey else {
                    noArticleToDeleteCompletion()
                    return
                }
                
                articleCacheController.remove(groupKey: articleKey, individualCompletion: { (itemResult) in
                    switch itemResult {
                    case .success(let itemKey):
                        DDLogDebug("🙈successfully removed \(itemKey)")
                    case .failure(let error):
                        DDLogDebug("🙈failure in itemCompletion of \(articleKey): \(error)")
                    }
                }) { (groupResult) in
                    DispatchQueue.main.async {
                        switch groupResult {
                        case .success:
                            DDLogDebug("🙈success in groupCompletion of \(articleKey)")
                            self.didRemoveArticle(with: articleKey)
                            self.updateCountOfFetchesInProcess()
                        case .failure:
                            DDLogDebug("🙈failure in groupCompletion of \(articleKey)")
                            break
                        }
                        updateAgain()
                    }
                }
            } else {
                noArticleToDeleteCompletion()
            }
        }
    }
    
    func didFetchArticle(with key: String) {
        operateOnArticles(with: key) { (article) in
            article.isDownloaded = true
        }
    }
    
    func didFailToFetchArticle(with key: String, error: Error) {
        operateOnArticles(with: key) { (article) in
            article.updatePropertiesForError(error)
            article.isDownloaded = !isErrorRecoverableOnRetry(error)
        }
    }
    
    func isErrorRecoverableOnRetry(_ error: Error) -> Bool {
        
        let error = error as NSError
        switch error.domain {
        case NSCocoaErrorDomain:
            switch error.code {
            case NSFileWriteOutOfSpaceError:
                let userInfo = [SavedArticlesFetcher.saveToDiskDidFailErrorKey: error]
                NotificationCenter.default.post(name: SavedArticlesFetcher.saveToDiskDidFail, object: self, userInfo: userInfo)
                stop()
            default:
                break
            }
            return true
        default:
            return true
        }
    }

    func didRemoveArticle(with key: String) {
        operateOnArticles(with: key) { (article) in
            article.isDownloaded = false
        }
    }
    
    func operateOnArticles(with key: String, articleBlock: (WMFArticle) -> Void) {
        do {
            let articles = try dataStore.viewContext.fetchArticles(withKey: key)
            for article in articles {
                articleBlock(article)
            }
        } catch (let error) {
            DDLogError("Error fetching WMFArticles after caching: \(error)");
        }
        
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
