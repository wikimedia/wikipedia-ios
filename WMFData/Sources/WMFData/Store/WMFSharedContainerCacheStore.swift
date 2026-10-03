import Foundation

public enum WMFSharedContainerCacheStoreError: Error {
    case unexpectedKeyCount
}

/// A `WMFKeyValueStore` that keeps each value in a `WMFSharedContainerCache` file. A one-part key is the file name. A two-part key is the subdirectory, then the file name.
public final class WMFSharedContainerCacheStore: WMFKeyValueStore, Sendable {

    private let containerURL: URL?

    /// - Parameter containerURL: The base folder of the cache. The default is the app group container. Tests can supply a temporary folder.
    public init(containerURL: URL? = WMFSharedContainerCache.defaultContainerURL) {
        self.containerURL = containerURL
    }

    public func load<T>(key: String...) throws -> T? where T: Decodable, T: Encodable {
        return try cache(for: key).loadCache()
    }

    public func save<T>(key: String..., value: T) throws where T: Decodable, T: Encodable {
        try cache(for: key).saveCache(value)
    }

    public func remove(key: String...) throws {
        let cache = try cache(for: key)
        try? cache.removeCache()
    }

    public func keys(inDirectory directory: String) throws -> [String] {
        WMFSharedContainerCache.fileNames(inSubdirectory: directory, containerURL: containerURL)
    }

    private func cache(for key: [String]) throws -> WMFSharedContainerCache {
        guard (1...2).contains(key.count) else {
            throw WMFSharedContainerCacheStoreError.unexpectedKeyCount
        }

        let fileName = key.count == 1 ? key[0] : key[1]
        let subdirectoryPathComponent = key.count == 2 ? key[0] : nil

        return WMFSharedContainerCache(fileName: fileName, subdirectoryPathComponent: subdirectoryPathComponent, containerURL: containerURL)
    }
}
