
import Foundation

final class ImageCacheFileWriter: CacheFileWriting {
    var delegate: CacheFileWritingDelegate?
    private let imageFetcher: ImageFetcher
    private let cacheBackgroundContext: NSManagedObjectContext
    
    init?(imageFetcher: ImageFetcher, cacheBackgroundContext: NSManagedObjectContext, delegate: CacheFileWritingDelegate? = nil) {
        self.imageFetcher = imageFetcher
        self.delegate = delegate
        self.cacheBackgroundContext = cacheBackgroundContext
        
        do {
            try FileManager.default.createDirectory(at: CacheController.cacheURL, withIntermediateDirectories: true, attributes: nil)
        } catch {
            assertionFailure("Failure to create article cache directory")
            return nil
        }
    }
    
    func download(cacheItem: PersistentCacheItem) {
        if cacheItem.isDownloaded == true {
            return
        }
        
        guard let key = cacheItem.key,
            let url = URL(string: key) else {
                return
        }
        
        imageFetcher.downloadData(url: url) { (error, _, temporaryFileURL, mimeType) in
            if let _ = error {
                //tonitodo: better error handling here
                return
            }
            guard let temporaryFileURL = temporaryFileURL else {
                return
            }
            
            CacheFileWriterHelper.moveFile(from: temporaryFileURL, toNewFileWithKey: key, mimeType: mimeType) { (result) in
                switch result {
                case .success:
                    self.delegate?.fileWriterDidDownload(cacheItem: cacheItem)
                default:
                    //tonitodo: better error handling
                    break
                }
            }
        }
    }
    
    func delete(cacheItem: PersistentCacheItem) {
        guard let key = cacheItem.key else {
            assertionFailure("cacheItem has no key")
            return
        }
        
        let pathComponent = key.sha256 ?? key
        
        let cachedFileURL = CacheController.cacheURL.appendingPathComponent(pathComponent, isDirectory: false)
        do {
            try FileManager.default.removeItem(at: cachedFileURL)
            delegate?.fileWriterDidDelete(cacheItem: cacheItem)
        } catch let error as NSError {
            if error.code == NSURLErrorFileDoesNotExist || error.code == NSFileNoSuchFileError {
                delegate?.fileWriterDidDelete(cacheItem: cacheItem)
            } else {
                delegate?.fileWriterDidFailToDelete(cacheItem: cacheItem, error: error)
            }
        }
    }
    
    
}
