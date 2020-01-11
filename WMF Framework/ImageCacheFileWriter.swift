
import Foundation

final class ImageCacheFileWriter: CacheFileWriting {
    var delegate: CacheFileWritingDelegate?
    private let imageFetcher: ImageFetcher
    private let cacheBackgroundContext: NSManagedObjectContext
    
    var groupedTasks: [String : [IdentifiedTask]] = [:]
    
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
    
    func add(groupKey: String, itemKey: String) {
        
        guard let url = URL(string: itemKey) else {
            return
        }
        
        let untrackKey = UUID().uuidString
        let task = imageFetcher.downloadData(url: url) { (error, _, temporaryFileURL, mimeType) in
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
                    self.delegate?.fileWriterDidAdd(groupKey: groupKey, itemKey: itemKey)
                default:
                    self.delegate?.fileWriterDidFailAdd(groupKey: groupKey, itemKey: itemKey)
                }
            }
            
            self.untrackTask(untrackKey: untrackKey, from: groupKey)
        }
        
        if let task = task {
            trackTask(untrackKey: untrackKey, task: task, to: groupKey)
        }
    }
    
    func remove(groupKey: String, itemKey: String) {

        let pathComponent = itemKey.sha256 ?? itemKey
        
        let cachedFileURL = CacheController.cacheURL.appendingPathComponent(pathComponent, isDirectory: false)
        do {
            try FileManager.default.removeItem(at: cachedFileURL)
            delegate?.fileWriterDidRemove(groupKey: groupKey, itemKey: itemKey)
        } catch let error as NSError {
            if error.code == NSURLErrorFileDoesNotExist || error.code == NSFileNoSuchFileError {
                delegate?.fileWriterDidRemove(groupKey: groupKey, itemKey: itemKey)
            } else {
                delegate?.fileWriterDidFailRemove(groupKey: groupKey, itemKey: itemKey)
            }
        }
    }
    
    
}
