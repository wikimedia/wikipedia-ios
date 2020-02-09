
import Foundation

enum ImageCacheFileWriterError: Error {
    case failureToGenerateURLFromItemKey
    case missingTemporaryFileURL
}

final class ImageCacheFileWriter: CacheFileWriting {
    private let imageFetcher: ImageFetcher
    private let cacheBackgroundContext: NSManagedObjectContext
    
    var groupedTasks: [String : [IdentifiedTask]] = [:]
    
    init?(imageFetcher: ImageFetcher, cacheBackgroundContext: NSManagedObjectContext) {
        self.imageFetcher = imageFetcher
        self.cacheBackgroundContext = cacheBackgroundContext
        
        do {
            try FileManager.default.createDirectory(at: CacheController.cacheURL, withIntermediateDirectories: true, attributes: nil)
        } catch {
            assertionFailure("Failure to create article cache directory")
            return nil
        }
    }
    
    func add(url: URL, groupKey: String, itemKey: String, completion: @escaping (CacheFileWritingResult) -> Void) {
        
        let untrackKey = UUID().uuidString
        let task = imageFetcher.downloadData(url: url) { (error, _, response, temporaryFileURL, mimeType) in
            
            defer {
                self.untrackTask(untrackKey: untrackKey, from: groupKey)
            }
            
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let temporaryFileURL = temporaryFileURL else {
                completion(.failure(ImageCacheFileWriterError.missingTemporaryFileURL))
                return
            }
            
            let etag = (response as? HTTPURLResponse)?.allHeaderFields[HTTPURLResponse.etagHeaderKey] as? String
            CacheFileWriterHelper.moveFile(from: temporaryFileURL, toNewFileWithKey: itemKey, mimeType: mimeType) { (result) in
                switch result {
                case .success, .exists:
                    completion(.success(etag: etag)) //tonitodo: when do we overwrite for .exists?
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }
        
        if let task = task {
            trackTask(untrackKey: untrackKey, task: task, to: groupKey)
        }
    }
}
