
import Foundation

protocol CacheFileWritingDelegate: class {
    func fileWriterDidDownload(groupKey: String, itemKey: String)
    func fileWriterDidDelete(groupKey: String, itemKey: String)
    func fileWriterDidFailToDelete(groupKey: String, itemKey: String)
}

protocol CacheFileWriting {
    
    var delegate: CacheFileWritingDelegate? { get }
    func download(groupKey: String, itemKey: String)
    func delete(groupKey: String, itemKey: String)
}

