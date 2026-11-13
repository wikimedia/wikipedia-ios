import Foundation

/// Gives tests outside of WMFDataMocks access to the JSON resources of this module.
public enum WMFDataMocksResources {
    public static func url(forResource name: String, withExtension ext: String = "json") -> URL? {
        return Bundle.module.url(forResource: name, withExtension: ext)
    }
}
