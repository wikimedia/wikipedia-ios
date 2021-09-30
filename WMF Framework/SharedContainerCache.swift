
import Foundation

final class SharedContainerCache<T: Codable> {
    
    //values must all be distinct
    enum PathComponent: String {
        case widgetCache = "Widget Cache"
        case pushNotificationsCache = "Push Notifications Cache"
    }
    
    private let pathComponent: PathComponent
    private let defaultCache: () -> T
    
    init(pathComponent: PathComponent, defaultCache: @escaping () -> T) {
        self.pathComponent = pathComponent
        self.defaultCache = defaultCache
    }
    
    private var cacheDirectoryContainerURL: URL {
        FileManager.default.wmf_containerURL()
    }
    
    fileprivate var cacheDataFileURL: URL {
        return cacheDirectoryContainerURL.appendingPathComponent(pathComponent.rawValue).appendingPathExtension("json")
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

        try? encodedCache.write(to: cacheDataFileURL)
    }
}
