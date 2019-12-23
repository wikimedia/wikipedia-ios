
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
        
        var cacheURL = fileManager.wmf_containerURL().appendingPathComponent("PersistentCache", isDirectory: true)
        
        var values = URLResourceValues()
        values.isExcludedFromBackup = true
        do {
            try cacheURL.setResourceValues(values)
        } catch {
            return nil
        }
        
        self.cacheURL = cacheURL
        
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
