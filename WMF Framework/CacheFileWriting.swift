
import Foundation

protocol CacheFileWritingDelegate: class {
    func fileWriterDidAdd(groupKey: String, itemKey: String)
    func fileWriterDidRemove(groupKey: String, itemKey: String)
    func fileWriterDidFailAdd(groupKey: String, itemKey: String)
    func fileWriterDidFailRemove(groupKey: String, itemKey: String)
}

protocol CacheFileWriting: CacheTaskTracking {
    
    var delegate: CacheFileWritingDelegate? { get }
    func add(groupKey: String, itemKey: String)
    
    //default extension
    func remove(groupKey: String, itemKey: String)
}

extension CacheFileWriting {
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
