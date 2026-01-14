import Foundation

@objc public extension FileManager {
    @objc func sizeOfDirectory(at url: URL) -> Int64 {
        var size: Int64 = 0
        let prefetchedProperties: [URLResourceKey] = [.isRegularFileKey, .fileAllocatedSizeKey, .totalFileAllocatedSizeKey]
        if let enumerator = self.enumerator(at: url, includingPropertiesForKeys: prefetchedProperties) {
            for item in enumerator {
                guard let itemURL = item as? NSURL else {
                    continue
                }
                let resourceValueForKey: (URLResourceKey) -> NSNumber? = { key in
                    var value: AnyObject? = nil
                    try? itemURL.getResourceValue(&value, forKey: key)
                    return value as? NSNumber
                }

                guard let isRegularFile = resourceValueForKey(URLResourceKey.isRegularFileKey)?.boolValue else {
                    continue
                }
                
                guard isRegularFile else {
                    continue
                }
                
                let fileSize = resourceValueForKey(URLResourceKey.totalFileAllocatedSizeKey) ?? resourceValueForKey(URLResourceKey.fileAllocatedSizeKey)
                guard let allocatedSize = fileSize?.int64Value else {
                    assertionFailure("URLResourceKey.fileAllocatedSizeKey should always return a value")
                    return size
                }
                size += allocatedSize
            }
        }
        return size
    }
}
