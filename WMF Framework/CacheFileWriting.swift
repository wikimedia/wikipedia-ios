
import Foundation

protocol CacheFileWritingDelegate: class {
    func fileWriterDidAdd(groupKey: String, itemKey: String)
    func fileWriterDidRemove(groupKey: String, itemKey: String)
    func fileWriterDidFailAdd(groupKey: String, itemKey: String)
    func fileWriterDidFailRemove(groupKey: String, itemKey: String)
}

enum CacheFileWritingResult {
    case success
    case failure(Error)
}

protocol CacheFileWriting: CacheTaskTracking {
    
    func add(groupKey: CacheController.GroupKey, itemKey: CacheController.ItemKey, completion: @escaping (CacheFileWritingResult) -> Void)
    
    //default extension
    func remove(itemKey: CacheController.ItemKey, completion: @escaping (CacheFileWritingResult) -> Void)
}

extension CacheFileWriting {
    func remove(itemKey: CacheController.ItemKey, completion: @escaping (CacheFileWritingResult) -> Void) {

        let pathComponent = itemKey.sha256 ?? itemKey

        let cachedFileURL = CacheController.cacheURL.appendingPathComponent(pathComponent, isDirectory: false)
        do {
            try FileManager.default.removeItem(at: cachedFileURL)
            completion(.success)
        } catch let error as NSError {
            if error.code == NSURLErrorFileDoesNotExist || error.code == NSFileNoSuchFileError {
                completion(.success)
            } else {
                completion(.failure(error))
            }
        }
    }
}
