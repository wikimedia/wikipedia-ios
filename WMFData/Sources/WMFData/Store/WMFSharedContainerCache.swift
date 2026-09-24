import Foundation

public enum WMFSharedContainerCacheError: Error {
    case missingContainerURL
}

/// Saves and loads one `Codable` value as a JSON file in the app group container, so that the app and its extensions can share it.
public final class WMFSharedContainerCache: Sendable {

    /// The Info.plist key that holds the app group identifier. Every target that uses this cache (the app, the widgets and the notification service extension) must set it to `$(WMF_APP_GROUP_IDENTIFIER)`.
    static let appGroupIdentifierInfoPlistKey = "WMFAppGroupIdentifier"

    /// The app group container of the current process, or `nil` if the Info.plist of the main bundle does not have the app group identifier.
    public static let defaultContainerURL: URL? = {
        guard let identifier = Bundle.main.object(forInfoDictionaryKey: appGroupIdentifierInfoPlistKey) as? String,
              !identifier.isEmpty else {
            return nil
        }
        return FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: identifier)
    }()

    private let fileName: String
    private let subdirectoryPathComponent: String?
    private let containerURL: URL?

    /// - Parameter containerURL: The base folder of the cache. The default is the app group container. Tests can supply a temporary folder.
    public init(fileName: String, subdirectoryPathComponent: String? = nil, containerURL: URL? = WMFSharedContainerCache.defaultContainerURL) {
        self.fileName = fileName
        self.subdirectoryPathComponent = subdirectoryPathComponent
        self.containerURL = containerURL
    }

    private var cacheDataFileURL: URL? {
        guard let baseURL = subdirectoryURL() ?? containerURL else {
            return nil
        }
        return baseURL.appendingPathComponent(fileName).appendingPathExtension("json")
    }

    private func subdirectoryURL() -> URL? {
        guard let subdirectoryPathComponent, let containerURL else {
            return nil
        }
        return containerURL.appendingPathComponent(subdirectoryPathComponent, isDirectory: true)
    }

    public func loadCache<T: Codable>() -> T? {
        if let cacheDataFileURL,
           let data = try? Data(contentsOf: cacheDataFileURL),
           let decodedCache = try? JSONDecoder().decode(T.self, from: data) {
            return decodedCache
        }
        return nil
    }

    public func saveCache<T: Codable>(_ cache: T) {
        guard let cacheDataFileURL,
              let encodedCache = try? JSONEncoder().encode(cache) else {
            return
        }

        if let subdirectoryURL = subdirectoryURL() {
            try? FileManager.default.createDirectory(at: subdirectoryURL, withIntermediateDirectories: true, attributes: nil)
        }

        try? encodedCache.write(to: cacheDataFileURL)
    }

    public func removeCache() throws {
        guard let cacheDataFileURL else {
            throw WMFSharedContainerCacheError.missingContainerURL
        }
        try FileManager.default.removeItem(at: cacheDataFileURL)
    }

    /// The names, without extension, of the JSON files cached under `subdirectoryPathComponent`.
    public static func fileNames(inSubdirectory subdirectoryPathComponent: String, containerURL: URL? = defaultContainerURL) -> [String] {
        guard let containerURL else {
            return []
        }
        let subdirectoryURL = containerURL.appendingPathComponent(subdirectoryPathComponent, isDirectory: true)
        guard let fileURLs = try? FileManager.default.contentsOfDirectory(at: subdirectoryURL, includingPropertiesForKeys: nil, options: .skipsHiddenFiles) else {
            return []
        }

        return fileURLs
            .filter { $0.pathExtension == "json" }
            .map { $0.deletingPathExtension().lastPathComponent }
    }

    /// Deletes the files in `subdirectoryPathComponent`, except the `maxItemCount` most recently modified files.
    public static func deleteStaleCachedItems(in subdirectoryPathComponent: String, keepingMostRecent maxItemCount: Int, containerURL: URL? = defaultContainerURL) {
        guard let containerURL else {
            return
        }
        let folderURL = containerURL.appendingPathComponent(subdirectoryPathComponent)

        if let urlArray = try? FileManager.default.contentsOfDirectory(at: folderURL,
                                                                       includingPropertiesForKeys: [.contentModificationDateKey],
                                                                       options: .skipsHiddenFiles) {
            if urlArray.count > maxItemCount {
                let sortedArray = urlArray.map { url in
                    (url, (try? url.resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate ?? Date.distantPast)
                }.sorted(by: { $0.1 > $1.1 })
                    .map { $0.0 }

                let itemsToDelete = Array(sortedArray.suffix(from: maxItemCount))
                for urlItem in itemsToDelete {
                    try? FileManager.default.removeItem(at: urlItem)
                }
            }
        }
    }
}
