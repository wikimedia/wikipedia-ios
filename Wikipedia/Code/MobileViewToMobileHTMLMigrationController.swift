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
