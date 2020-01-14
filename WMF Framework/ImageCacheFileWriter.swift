
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
            self.delegate?.fileWriterDidFailAdd(groupKey: groupKey, itemKey: itemKey)
            return
        }
        
        let untrackKey = UUID().uuidString
        let task = imageFetcher.downloadData(url: url) { (error, _, temporaryFileURL, mimeType) in
            
            defer {
                self.untrackTask(untrackKey: untrackKey, from: groupKey)
            }
            
            if let _ = error {
                self.delegate?.fileWriterDidFailAdd(groupKey: groupKey, itemKey: itemKey)
                return
            }
            guard let temporaryFileURL = temporaryFileURL else {
                self.delegate?.fileWriterDidFailAdd(groupKey: groupKey, itemKey: itemKey)
                return
            }
            
            CacheFileWriterHelper.moveFile(from: temporaryFileURL, toNewFileWithKey: itemKey, mimeType: mimeType) { (result) in
                switch result {
                case .success, .exists:
                    self.delegate?.fileWriterDidAdd(groupKey: groupKey, itemKey: itemKey)
                case .failure:
                    self.delegate?.fileWriterDidFailAdd(groupKey: groupKey, itemKey: itemKey)
                }
            }
        }
        
        if let task = task {
            trackTask(untrackKey: untrackKey, task: task, to: groupKey)
        }
    }
}
