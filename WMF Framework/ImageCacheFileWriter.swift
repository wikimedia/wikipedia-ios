
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
    
    func download(groupKey: String, itemKey: String) {
        
        guard let url = URL(string: itemKey) else {
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
            
            CacheFileWriterHelper.moveFile(from: temporaryFileURL, toNewFileWithKey: itemKey, mimeType: mimeType) { (result) in
                switch result {
                case .success:
                    self.delegate?.fileWriterDidDownload(groupKey: groupKey, itemKey: itemKey)
                default:
                    //tonitodo: better error handling
                    break
                }
            }
        }
    }
    
    func delete(groupKey: String, itemKey: String) {

        let pathComponent = itemKey.sha256 ?? itemKey
        
        let cachedFileURL = CacheController.cacheURL.appendingPathComponent(pathComponent, isDirectory: false)
        do {
            try FileManager.default.removeItem(at: cachedFileURL)
            delegate?.fileWriterDidDelete(groupKey: groupKey, itemKey: itemKey)
        } catch let error as NSError {
            if error.code == NSURLErrorFileDoesNotExist || error.code == NSFileNoSuchFileError {
                delegate?.fileWriterDidDelete(groupKey: groupKey, itemKey: itemKey)
            } else {
                delegate?.fileWriterDidFailToDelete(groupKey: groupKey, itemKey: itemKey)
            }
        }
    }
    
    
}
