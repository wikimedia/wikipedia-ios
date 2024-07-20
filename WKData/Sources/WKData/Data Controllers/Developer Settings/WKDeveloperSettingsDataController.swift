import Foundation

public final class WKDeveloperSettingsDataController {
    
    public static let shared = WKDeveloperSettingsDataController()
    
    private let userDefaultsStore = WKDataEnvironment.current.userDefaultsStore
    
    public var doNotPostImageRecommendationsEdit: Bool {
        get {
            return (try? userDefaultsStore?.load(key: WKUserDefaultsKey.developerSettingsDoNotPostImageRecommendationsEdit.rawValue)) ?? false
        } set {
            try? userDefaultsStore?.save(key: WKUserDefaultsKey.developerSettingsDoNotPostImageRecommendationsEdit.rawValue, value: newValue)
        }
    }
}
