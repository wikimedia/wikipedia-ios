import Foundation

public final class SharedContainerCache<T: Codable> {
    
    // values must all be distinct
    public enum PathComponent: String {
        case widgetCache = "Widget Cache"
        case pushNotificationsCache = "Push Notifications Cache"
        case userDataExportSyncInfo = "User Data Export Sync Info"
        case talkPageCache = "Talk Page Cache"
    }
    
    private let pathComponent: PathComponent
    private let defaultCache: () -> T
    
    public init(pathComponent: PathComponent, defaultCache: @escaping () -> T) {
        self.pathComponent = pathComponent
        self.defaultCache = defaultCache
    }
    
    private var cacheDirectoryContainerURL: URL {
        FileManager.default.wmf_containerURL()
    }
    
    private var cacheDataFileURL: URL {
        return cacheDirectoryContainerURL.appendingPathComponent(pathComponent.rawValue).appendingPathExtension("json")
    }
    
    private func subdirectoryFileURL(to subfolder: String) -> URL {
        return cacheDirectoryContainerURL
            .appendingPathComponent(pathComponent.rawValue, isDirectory: true)
//            .appendingPathComponent(subfolder)
//            .appendingPathExtension("json")
    }

    func cacheFileURL(to subfolder: String) -> URL {
        return cacheDirectoryContainerURL
            .appendingPathComponent(pathComponent.rawValue, isDirectory: true)
            .appendingPathComponent(subfolder)
            .appendingPathExtension("json")
    }
    
    public func loadCache() -> T {
        if let data = try? Data(contentsOf: cacheDataFileURL), let decodedCache = try? JSONDecoder().decode(T.self, from: data) {
            return decodedCache
        }

        return defaultCache()
    }
    
    public func loadCache(for folder: String) -> T {
        let cacheFolderURL = cacheFileURL(to: folder)
        
        if let data = try? Data(contentsOf: cacheFolderURL),
            let decodedCache = try? JSONDecoder().decode(T.self, from: data) {

            return decodedCache
        }

        return defaultCache()
    }

    public func saveCache(_ cache: T) {
        let encoder = JSONEncoder()
        guard let encodedCache = try? encoder.encode(cache) else {
            return
        }
        try? encodedCache.write(to: cacheDataFileURL)
    }
    
    public func saveCache(to folder: String, _ cache: T) {
        let encoder = JSONEncoder()
        guard let encodedCache = try? encoder.encode(cache) else {
            return
        }

        let subdirectoryPath = subdirectoryFileURL(to: folder)
        let filePath = cacheFileURL(to: folder)
        print(filePath)
        do {
            try FileManager.default.createDirectory(at: subdirectoryPath, withIntermediateDirectories: true, attributes: nil)
            try encodedCache.write(to: filePath)
        } catch {
            print(error)
        }

    }

    /// Persist only the last 50 visited talk pages
    @objc public func deleteStaleTalkPages() {
        let folderURL = cacheDirectoryContainerURL.appendingPathComponent(pathComponent.rawValue)

        if let urlArray = try? FileManager.default.contentsOfDirectory(at: folderURL,
                                                                       includingPropertiesForKeys: [.contentModificationDateKey],
                                                                       options: .skipsHiddenFiles) {
            if urlArray.count > 50 {
                let sortedArray =  urlArray.map { url in
                    (url, (try? url.resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate ?? Date.distantPast)
                }.sorted(by: {$0.1 > $1.1 })
                    .map { $0.0 }

                let itemsToDelete = Array(sortedArray.suffix(from: 51))
                for urlItem in itemsToDelete {
                    try? FileManager.default.removeItem(at: urlItem)
                }
            }
        }

    }
}
