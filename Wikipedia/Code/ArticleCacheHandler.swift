
import Foundation

//Wrapper class around the Article Cache classes for singleton access (:/) and shared file managers / managed object contexts / cacheURLs/ file managers

@objc(WMFArticleCacheHandler)
public final class ArticleCacheHandler: NSObject {
    public let dbWriter: ArticleCacheDBWriter
    public let cacheProvider: ArticleCacheProvider
    private let fetcher: ArticleFetcher
    private let fileManager: FileManager
    @objc public let fileWriter: ArticleCacheFileWriter
    
    @objc public static let shared: ArticleCacheHandler? = ArticleCacheHandler()
    
    @objc public init?(fetcher: ArticleFetcher = ArticleFetcher(),
                       fileManager: FileManager = FileManager.default) {
        self.fetcher = fetcher
        self.fileManager = fileManager
        
        guard let dbWriter = ArticleCacheDBWriter(articleFetcher: fetcher, fileManager: fileManager) else {
            return nil
        }
        self.dbWriter = dbWriter
        let fileWriter = ArticleCacheFileWriter(moc: dbWriter.cacheBackgroundContext, articleFetcher: fetcher, cacheURL: dbWriter.cacheURL, fileManager: fileManager, dbDelegate: dbWriter)
        
        self.fileWriter = fileWriter
        self.cacheProvider = ArticleCacheProvider(fileWriter: fileWriter, fileManager: fileManager)
    }
}
