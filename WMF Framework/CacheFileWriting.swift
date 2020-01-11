
import Foundation

protocol CacheFileWritingDelegate: class {
    func fileWriterDidAdd(groupKey: String, itemKey: String)
    func fileWriterDidRemove(groupKey: String, itemKey: String)
    func fileWriterDidFailAdd(groupKey: String, itemKey: String)
    func fileWriterDidFailRemove(groupKey: String, itemKey: String)
}

protocol CacheFileWriting {
    
    var delegate: CacheFileWritingDelegate? { get }
    func add(groupKey: String, itemKey: String)
    func remove(groupKey: String, itemKey: String)
}

