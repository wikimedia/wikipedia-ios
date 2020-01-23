import Foundation

final class SchemeHandlerCache {
    static private let cachedResponseCountLimit = UInt(6)
    let responseCache = WMFFIFOCache<NSString, CachedURLResponse>(countLimit: SchemeHandlerCache.cachedResponseCountLimit)
}
