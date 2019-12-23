
import Foundation

//Wrapper class around the Article Cache classes for singleton access (:/) and shared file managers / managed object contexts / cacheURLs/ file managers

@objc(WMFArticleCacheHandler)
public final class ArticleCacheHandler: NSObject {
    public let dbWriter: ArticleCacheDBWriter
    public let cacheProvider: ArticleCacheProvider
    private let fetcher: ArticleFetcher
    private let fileManager: FileManager
    @objc public let fileWriter: ArticleCacheFileWriter
    private let cacheURL: URL
    
    @objc public static let shared: ArticleCacheHandler? = ArticleCacheHandler()
    
    @objc public init?(fetcher: ArticleFetcher = ArticleFetcher(),
                       fileManager: FileManager = FileManager.default) {
        self.fetcher = fetcher
        self.fileManager = fileManager
        
        //create cacheURL and directory
        guard let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).last else {
            assertionFailure("Failure to pull documents directory")
            return nil
        }
        
        let documentsURL = URL(fileURLWithPath: documentsPath)
        cacheURL = documentsURL.appendingPathComponent("PersistentArticleCache", isDirectory: true)
        
        guard let dbWriter = ArticleCacheDBWriter(articleFetcher: fetcher, cacheURL: cacheURL) else {
            return nil
        }
        self.dbWriter = dbWriter
        
        guard let fileWriter = ArticleCacheFileWriter(moc: dbWriter.cacheBackgroundContext, articleFetcher: fetcher, cacheURL: cacheURL, fileManager: fileManager, dbDelegate: dbWriter) else {
            return nil
        }
        
        self.fileWriter = fileWriter
        self.cacheProvider = ArticleCacheProvider(fileWriter: fileWriter, fileManager: fileManager)
    }
}
