import Foundation
import MetricKit
import CocoaLumberjackSwift

@objc public class SharedContainerCacheCommonNames: NSObject {
    @objc public static let pushNotificationsCache = "Push Notifications Cache"
    @objc public static let talkPageCache = "Talk Page Cache"
    public static let widgetCache = "Widget Cache"
}

public final class SharedContainerCache<T: Codable>: SharedContainerCacheHousekeepingProtocol {

    private let fileName: String
    private let subdirectoryPathComponent: String?
    private let defaultCache: () -> T
    
    public init(fileName: String, subdirectoryPathComponent: String? = nil, defaultCache: @escaping () -> T) {
        self.fileName = fileName
        self.subdirectoryPathComponent = subdirectoryPathComponent
        self.defaultCache = defaultCache
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

    public func loadCache() -> T {
        if let data = try? Data(contentsOf: cacheDataFileURL), let decodedCache = try? JSONDecoder().decode(T.self, from: data) {
            return decodedCache
        }
        return defaultCache()
    }

    public func saveCache(_ cache: T) {
        let encoder = JSONEncoder()
        guard let encodedCache = try? encoder.encode(cache) else {
            return
        }

        if let subdirectoryURL = subdirectoryURL() {
            try? FileManager.default.createDirectory(at: subdirectoryURL, withIntermediateDirectories: true, attributes: nil)

        }

        try? encodedCache.write(to: cacheDataFileURL)
    }

    /// Persist only the last 50 visited talk pages
    @objc public static func deleteStaleCachedItems(in subdirectoryPathComponent: String) {
        let folderURL = cacheDirectoryContainerURL.appendingPathComponent(subdirectoryPathComponent)

        if let urlArray = try? FileManager.default.contentsOfDirectory(at: folderURL,
                                                                       includingPropertiesForKeys: [.contentModificationDateKey],
                                                                       options: .skipsHiddenFiles) {
            let maxCacheSize = 50
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
    static func deleteStaleCachedItems(in subdirectoryPathComponent: String)
}

@objc public class SharedContainerCacheClearFeaturedArticleWrapper: NSObject {
    @objc public static func clearOutFeaturedArticleWidgetCache() {
        let sharedCache = SharedContainerCache<WidgetCache>(fileName: SharedContainerCacheCommonNames.widgetCache, defaultCache: { WidgetCache(settings: .default, featuredContent: nil) })
        var updatedCache = sharedCache.loadCache()
        updatedCache.featuredContent = nil
        sharedCache.saveCache(updatedCache)
    }
}

@objc public class SharedContainerCacheMetricKitWrapper: NSObject {
    @objc public static func saveBackgroundExitData(payloads: [MXMetricPayload]) {
        let containerURL = FileManager.default.wmf_containerURL()
        let fileURL = containerURL.appendingPathComponent("metricKitBackgroundExitData").appendingPathExtension("json")
        var mutableArray = NSMutableArray()
        for payload in payloads {
            var exitData = NSMutableDictionary()
            exitData["timeStampBegin"] = DateFormatter.wmf_iso8601().string(from: payload.timeStampBegin)
            exitData["timeStampEnd"] = DateFormatter.wmf_iso8601().string(from: payload.timeStampEnd)
            exitData["cumulativeNormalAppExitCount"] = payload.applicationExitMetrics?.backgroundExitData.cumulativeNormalAppExitCount
            exitData["cumulativeMemoryResourceLimitExitCount"] = payload.applicationExitMetrics?.backgroundExitData.cumulativeMemoryResourceLimitExitCount
            exitData["cumulativeMemoryPressureExitCount"] = payload.applicationExitMetrics?.backgroundExitData.cumulativeMemoryPressureExitCount
            exitData["cumulativeBadAccessExitCount"] = payload.applicationExitMetrics?.backgroundExitData.cumulativeBadAccessExitCount
            exitData["cumulativeAbnormalExitCount"] = payload.applicationExitMetrics?.backgroundExitData.cumulativeAbnormalExitCount
            exitData["cumulativeIllegalInstructionExitCount"] = payload.applicationExitMetrics?.backgroundExitData.cumulativeIllegalInstructionExitCount
            exitData["cumulativeAppWatchdogExitCount"] = payload.applicationExitMetrics?.backgroundExitData.cumulativeAppWatchdogExitCount
            exitData["cumulativeSuspendedWithLockedFileExitCount"] = payload.applicationExitMetrics?.backgroundExitData.cumulativeSuspendedWithLockedFileExitCount
            exitData["cumulativeBackgroundTaskAssertionTimeoutExitCount"] = payload.applicationExitMetrics?.backgroundExitData.cumulativeBackgroundTaskAssertionTimeoutExitCount
            exitData["cumulativeCPUResourceLimitExitCount"] = payload.applicationExitMetrics?.backgroundExitData.cumulativeCPUResourceLimitExitCount
            mutableArray.add(NSDictionary(dictionary: exitData))
        }
        do {
            if let data = try? Data(contentsOf: fileURL),
               let currentExitData = try? JSONSerialization.jsonObject(with: data, options: []) as? [Any] {
                mutableArray.addObjects(from: currentExitData)
            }
            try? FileManager.default.removeItem(at: fileURL)
            let data = try JSONSerialization.data(withJSONObject: NSArray(array: mutableArray), options: [.prettyPrinted])
            try data.write(to: fileURL, options: [.atomicWrite])
        } catch {
            DDLogError("Error saving metric payload: \(error)")
        }
    }
}
