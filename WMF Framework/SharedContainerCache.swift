import Foundation

@objc public class SharedContainerCacheCommonNames: NSObject {
    @objc public static let pushNotificationsCache = "Push Notifications Cache"
    @objc public static let talkPageCache = "Talk Page Cache"
    public static let widgetCache = "Widget Cache"
}

public final class SharedContainerCache: SharedContainerCacheHousekeepingProtocol {

    private let fileName: String
    private let subdirectoryPathComponent: String?
    
    public init(fileName: String, subdirectoryPathComponent: String? = nil) {
        self.fileName = fileName
        self.subdirectoryPathComponent = subdirectoryPathComponent
    }
    
    private static var cacheDirectoryContainerURL: URL {
        FileManager.default.wmf_containerURL()
    }
    
    private var cacheDataFileURL: URL {
        let baseURL = subdirectoryURL() ?? Self.cacheDirectoryContainerURL
        return baseURL.appendingPathComponent(fileName).appendingPathExtension("json")
    }
    
    private func subdirectoryURL() -> URL? {
        guard let subdirectoryPathComponent = subdirectoryPathComponent else {
            return nil
        }
        return Self.cacheDirectoryContainerURL.appendingPathComponent(subdirectoryPathComponent, isDirectory: true)
    }

    public func loadCache<T: Codable>() -> T? {
        if let data = try? Data(contentsOf: cacheDataFileURL), let decodedCache = try? JSONDecoder().decode(T.self, from: data) {
            return decodedCache
        }
        return nil
    }

    public func saveCache<T: Codable>(_ cache: T) {
        let encoder = JSONEncoder()
        guard let encodedCache = try? encoder.encode(cache) else {
            return
        }

        if let subdirectoryURL = subdirectoryURL() {
            try? FileManager.default.createDirectory(at: subdirectoryURL, withIntermediateDirectories: true, attributes: nil)

        }

        try? encodedCache.write(to: cacheDataFileURL)
    }
    
    public func removeCache() throws {
        try FileManager.default.removeItem(at: cacheDataFileURL)
    }

    /// Persist only the last 50 visited talk pages
    @objc public static func deleteStaleCachedItems(in subdirectoryPathComponent: String, cleanupLevel: WMFCleanupLevel) {
        let folderURL = cacheDirectoryContainerURL.appendingPathComponent(subdirectoryPathComponent)

        if let urlArray = try? FileManager.default.contentsOfDirectory(at: folderURL,
                                                                       includingPropertiesForKeys: [.contentModificationDateKey],
                                                                       options: .skipsHiddenFiles) {
            let maxCacheSize = cleanupLevel == .high ? 0 : 50
            if urlArray.count > maxCacheSize {
                let sortedArray =  urlArray.map { url in
                    (url, (try? url.resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate ?? Date.distantPast)
                }.sorted(by: {$0.1 > $1.1 })
                    .map { $0.0 }

                let itemsToDelete = Array(sortedArray.suffix(from: maxCacheSize))
                for urlItem in itemsToDelete {
                    try? FileManager.default.removeItem(at: urlItem)
                }
            }
        }

    }
}

@objc public protocol SharedContainerCacheHousekeepingProtocol: AnyObject {
    static func deleteStaleCachedItems(in subdirectoryPathComponent: String, cleanupLevel: WMFCleanupLevel)
}

@objc public class SharedContainerCacheClearFeaturedArticleWrapper: NSObject {
    @objc public static func clearOutFeaturedArticleWidgetCache() {
        let sharedCache = SharedContainerCache(fileName: SharedContainerCacheCommonNames.widgetCache)
        var updatedCache = sharedCache.loadCache() ?? WidgetCache(settings: .default, featuredContent: nil)
        updatedCache.featuredContent = nil
        sharedCache.saveCache(updatedCache)
    }
}
